import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../animation/domain/cut_timeline.dart';
import '../../animation/domain/smash_config.dart';
import '../../export/export_service.dart';
import '../../image_processing/services/image_loader.dart';
import '../../settings/preferences.dart';
import '../domain/cut_operation.dart';
import '../domain/edit_history.dart';
import '../domain/selection_state.dart';
import '../domain/strip_document.dart';
import '../domain/viewport_transform.dart';
import 'doc_source.dart';

enum LineHandle { a, b }

/// Un frammento della fascia distrutta da SMASH.
class Shard {
  Shard(this.src, this.dst, this.velocity, this.spin);
  final Rect src;
  final Rect dst;
  final Offset velocity;
  final double spin;
}

/// Un taglio in corso di animazione. Il risultato è già calcolato: qui c'è
/// solo ciò che serve a mostrarlo.
class CutAnimation {
  CutAnimation({
    required this.op,
    required this.before,
    required this.after,
    required this.t0,
    required this.t1,
    required this.timeline,
    required this.placement,
    required this.shards,
  });

  final CutOperation op;
  final DocSource before;
  final DocSource after;
  final ViewportTransform t0;
  final ViewportTransform t1;
  final CutTimeline timeline;
  final SmashPlacement? placement;
  final List<Shard> shards;
  double elapsedMs = 0;
  bool committed = false;
}

/// Stato e logica dell'editor. I widget leggono da qui e chiamano i metodi;
/// il taglio vero è fatto dal modello [StripDocument], non dall'animazione.
class EditorController extends ChangeNotifier {
  EditorController({
    required LoadedImage image,
    required this.preferences,
    this.settings = const CutAnimationSettings(),
    this.exporter = const ExportService(),
  }) {
    _open(image);
    smashEnabled = preferences.smashEnabled;
  }

  final AppPreferences preferences;
  final CutAnimationSettings settings;
  final ExportService exporter;

  /// Notifica i ridisegni durante l'animazione senza ricostruire i widget.
  final ValueNotifier<int> frameTick = ValueNotifier(0);

  late LoadedImage source;
  late EditHistory _history;
  late DocSource _view;
  late SelectionState selection;
  bool smashEnabled = true;

  /// Diventa vero quando i frame di SMASH sono caricati.
  bool smashAvailable = false;
  bool _selectionSuppressed = false;
  CutAnimation? animation;
  Timer? _reappear;
  bool busyExporting = false;

  double zoom = 1;
  Offset pan = Offset.zero;
  Size viewportSize = Size.zero;
  LineHandle? draggingHandle;

  // --- lettura dello stato -------------------------------------------------

  StripDocument get doc => _history.current;
  DocSource get view => _view;
  bool get canUndo => _history.canUndo && !isCutting;
  bool get canRedo => _history.canRedo && !isCutting;
  bool get isCutting => animation != null && !animation!.committed;
  bool get isAnimating => animation != null;

  /// La selezione è visibile (non nascosta dall'utente né in attesa).
  bool get selectionVisible => selection.isVisible && !_selectionSuppressed;
  CutOrientation get layoutOrientation => selection.mode ?? selection.lastMode;

  bool get canCut =>
      selectionVisible && !isCutting && !busyExporting && _pendingCut() != null;

  ViewportTransform get transform => ViewportTransform(
    viewport: viewportSize,
    content: Size(doc.width.toDouble(), doc.height.toDouble()),
    gutters: Gutters.forOrientation(layoutOrientation),
    zoom: zoom,
    pan: pan,
  ).clamped();

  // --- documento -----------------------------------------------------------

  void _open(LoadedImage image) {
    source = image;
    _history = EditHistory(StripDocument.original(image.width, image.height));
    _view = DocSource.build(image.image, doc);
    selection = SelectionState.initial(width: doc.width, height: doc.height);
    _selectionSuppressed = false;
    zoom = 1;
    pan = Offset.zero;
  }

  /// Sostituisce il documento con una nuova immagine importata.
  void replaceImage(LoadedImage image) {
    _cancelAnimation();
    final old = _view;
    final oldSource = source;
    _open(image);
    old.dispose();
    if (!identical(oldSource.image, image.image)) oldSource.image.dispose();
    notifyListeners();
  }

  void setViewportSize(Size s) => viewportSize = s;

  // --- selezione -----------------------------------------------------------

  void tapOrientation(CutOrientation o) {
    if (isCutting) return;
    if (_selectionSuppressed) {
      _reappear?.cancel();
      _selectionSuppressed = false;
      selection = selection
          .shown(o)
          .ensureValid(width: doc.width, height: doc.height);
    } else {
      selection = selection.tap(o, width: doc.width, height: doc.height);
    }
    pan = transform.pan;
    notifyListeners();
  }

  void startLineDrag(LineHandle h) {
    if (isCutting || !selectionVisible) return;
    draggingHandle = h;
    notifyListeners();
  }

  void dragLineTo(Offset viewportPos) {
    final h = draggingHandle;
    final mode = selection.mode;
    if (h == null || mode == null) return;
    final c = transform.screenToContent(viewportPos);
    final len = doc.lengthFor(mode);
    final v = (mode == CutOrientation.horizontal ? c.dy : c.dx)
        .clamp(0, len)
        .roundToDouble();
    final pair = selection.lines[mode]!;
    selection = selection.withLines(
      mode,
      h == LineHandle.a ? pair.withA(v) : pair.withB(v),
    );
    notifyListeners();
  }

  void endLineDrag() {
    if (draggingHandle == null) return;
    draggingHandle = null;
    notifyListeners();
  }

  // --- zoom e spostamento --------------------------------------------------

  double _zoom0 = 1;
  Offset _pan0 = Offset.zero;
  Offset _focal0 = Offset.zero;

  void setZoom(double z) {
    final t = transform.zoomedAround(viewportSize.center(Offset.zero), z);
    zoom = t.zoom;
    pan = t.pan;
    notifyListeners();
  }

  void gestureStart(Offset focal) {
    _zoom0 = zoom;
    _pan0 = pan;
    _focal0 = focal;
  }

  void gestureUpdate(Offset focal, double scale) {
    if (draggingHandle != null || isCutting) return;
    final base = transform.copyWith(zoom: _zoom0, pan: _pan0);
    final t = base
        .zoomedAround(_focal0, _zoom0 * scale)
        .panned(focal - _focal0);
    if (t.zoom == zoom && t.pan == pan) return;
    zoom = t.zoom;
    pan = t.pan;
    notifyListeners();
  }

  // --- taglio --------------------------------------------------------------

  CutOperation? _pendingCut() {
    final mode = selection.mode;
    final pair = selection.active;
    if (mode == null || pair == null) return null;
    return CutOperation.fromLines(
      orientation: mode,
      a: pair.a,
      b: pair.b,
      length: doc.lengthFor(mode),
    );
  }

  /// Avvia il taglio. Restituisce `false` se la selezione non è valida.
  bool removePortion() {
    if (!canCut) return false;
    final op = _pendingCut()!;
    final before = _view;
    final t0 = transform;
    final afterDoc = doc.apply(op);
    final after = DocSource.build(source.image, afterDoc);
    final t1 = t0.copyWith(
      content: Size(afterDoc.width.toDouble(), afterDoc.height.toDouble()),
    );
    final smash = smashEnabled && smashAvailable;
    final timeline = CutTimeline(settings: settings, smash: smash);
    final impact = _impactPoint(t0, op);
    animation = CutAnimation(
      op: op,
      before: before,
      after: after,
      t0: t0,
      t1: t1,
      timeline: timeline,
      placement: smash
          ? SmashPlacement(
              viewport: viewportSize,
              impact: impact,
              robotHeight: viewportSize.width * settings.robotHeightFraction,
            )
          : null,
      shards: smash ? _makeShards(t0, op, impact) : const [],
    );
    _selectionSuppressed = true;
    notifyListeners();
    return true;
  }

  /// Epicentro: a metà tra A e B sull'asse del taglio, al centro della parte
  /// visibile del documento sull'altro asse.
  Offset _impactPoint(ViewportTransform t, CutOperation op) {
    final visible = t.contentRect.intersect(Offset.zero & viewportSize);
    final mid = (op.start + op.end) / 2;
    if (op.orientation == CutOrientation.horizontal) {
      final y = t.contentToScreen(Offset(0, mid)).dy;
      return Offset(
        visible.center.dx,
        y.clamp(0, viewportSize.height).toDouble(),
      );
    }
    final x = t.contentToScreen(Offset(mid, 0)).dx;
    return Offset(x.clamp(0, viewportSize.width).toDouble(), visible.center.dy);
  }

  List<Shard> _makeShards(ViewportTransform t, CutOperation op, Offset impact) {
    final w = doc.width.toDouble(), h = doc.height.toDouble();
    final src = op.orientation == CutOrientation.horizontal
        ? Rect.fromLTWH(0, op.start.toDouble(), w, op.removed.toDouble())
        : Rect.fromLTWH(op.start.toDouble(), 0, op.removed.toDouble(), h);
    final dst = t.regionToScreen(src);
    final cols = (dst.width / 38).round().clamp(3, 12);
    final rows = (dst.height / 38).round().clamp(2, 12);
    var seed = 7;
    double rnd() => (seed = seed * 16807 % 2147483647) / 2147483647;
    final out = <Shard>[];
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final s = Rect.fromLTWH(
          src.left + src.width * i / cols,
          src.top + src.height * j / rows,
          src.width / cols,
          src.height / rows,
        );
        final d = Rect.fromLTWH(
          dst.left + dst.width * i / cols,
          dst.top + dst.height * j / rows,
          dst.width / cols,
          dst.height / rows,
        );
        final dir = d.center - impact;
        final n = dir.distance == 0 ? const Offset(1, 0) : dir / dir.distance;
        final speed = 260 + rnd() * 420;
        // il pugno arriva da sinistra: i frammenti volano soprattutto a destra
        final v =
            n * speed +
            Offset(
              op.orientation == CutOrientation.horizontal ? 180 : 0,
              -220 * rnd(),
            );
        out.add(Shard(s, d, v, (rnd() - .5) * 12));
      }
    }
    return out;
  }

  /// Chiamato a ogni fotogramma dal ticker dell'editor.
  void tick(Duration elapsed) {
    final a = animation;
    if (a == null) return;
    a.elapsedMs = elapsed.inMicroseconds / 1000;
    if (!a.committed && a.elapsedMs >= a.timeline.joinEndMs) _commit(a);
    if (a.elapsedMs >= a.timeline.endMs) {
      animation = null;
      a.before.dispose();
      notifyListeners();
    }
    frameTick.value++;
  }

  void _commit(CutAnimation a) {
    a.committed = true;
    _history.push(a.op);
    _view = a.after;
    zoom = a.t1.zoom;
    pan = a.t1.pan;
    selection = selection.afterCut(
      a.op.orientation,
      width: doc.width,
      height: doc.height,
    );
    // il conteggio parte solo ora, a ricongiungimento completato
    _reappear?.cancel();
    _reappear = Timer(settings.reappearDelay, () {
      _selectionSuppressed = false;
      notifyListeners();
    });
    notifyListeners();
  }

  void _cancelAnimation() {
    final a = animation;
    animation = null;
    _reappear?.cancel();
    _selectionSuppressed = false;
    if (a != null) {
      if (!a.committed) a.after.dispose();
      if (a.committed) a.before.dispose();
    }
  }

  // --- cronologia ----------------------------------------------------------

  void undo() => _step(_history.undo);
  void redo() => _step(_history.redo);

  void _step(bool Function() move) {
    if (isCutting) return;
    _cancelAnimation();
    if (!move()) return;
    final old = _view;
    _view = DocSource.build(source.image, doc);
    old.dispose();
    selection = selection.ensureValid(width: doc.width, height: doc.height);
    pan = transform.pan;
    notifyListeners();
  }

  // --- SMASH ----------------------------------------------------------------

  void setSmash(bool on) {
    smashEnabled = on;
    preferences.setSmashEnabled(on);
    notifyListeners();
  }

  // --- esportazione ---------------------------------------------------------

  Future<ExportedFile?> buildExport() async {
    if (busyExporting) return null;
    busyExporting = true;
    notifyListeners();
    try {
      return await exporter.build(source, doc);
    } finally {
      busyExporting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelAnimation();
    _view.dispose();
    frameTick.dispose();
    super.dispose();
  }
}
