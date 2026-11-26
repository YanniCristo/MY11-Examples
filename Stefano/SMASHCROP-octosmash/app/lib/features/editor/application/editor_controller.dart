import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../../animation/domain/cut_timeline.dart';
import '../../animation/domain/smash_config.dart';
import '../../rubble/domain/rubble_math.dart';
import '../../export/export_service.dart';
import '../../octo/domain/octo_rect.dart';
import '../../export/images_pdf.dart';
import '../../image_processing/services/image_loader.dart';
import '../../pdf_processing/domain/page_layout.dart';
import '../../pdf_processing/services/pdf_service.dart';
import '../../settings/preferences.dart';
import '../../settings/work_file/work_file_store.dart';
import '../domain/cut_operation.dart';
import '../domain/selection_state.dart';
import '../domain/strip_document.dart';
import '../domain/viewport_transform.dart';
import 'doc_source.dart';
import 'editor_page.dart';
import 'saved_work.dart';

enum LineHandle { a, b }

enum DocumentKind { image, pdf }

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
    required this.page,
    required this.op,
    required this.before,
    required this.after,
    required this.frame0,
    required this.frame1,
    required this.t0,
    required this.t1,
    required this.timeline,
    required this.placement,
    required this.shards,
    required this.firstCutOnPdfPage,
    this.stripRect = Rect.zero,
    this.rubbleKg = 0,
  });

  /// La fascia tolta, a schermo (coordinate del viewport).
  final Rect stripRect;

  /// Macerie di questo taglio (0 con SMASH spento).
  final double rubbleKg;

  final EditorPage page;
  final CutOperation op;
  final DocSource before;
  final DocSource after;
  final PageFrame frame0;
  final PageFrame frame1;
  final ViewportTransform t0;
  final ViewportTransform t1;
  final CutTimeline timeline;
  final SmashPlacement? placement;
  final List<Shard> shards;
  final bool firstCutOnPdfPage;
  double elapsedMs = 0;

  /// Le macerie sono già state contate (succede una volta sola).
  bool rubbleCounted = false;
  bool committed = false;
}

/// Stato e logica dell'editor, per immagini e PDF. I widget leggono da qui
/// e chiamano i metodi; il taglio vero è fatto dal modello [StripDocument],
/// non dall'animazione.
class EditorController extends ChangeNotifier {
  EditorController.image({
    required LoadedImage image,
    required this.preferences,
    this.settings = const CutAnimationSettings(),
    this.exporter = const ExportService(),
  }) {
    _openImages(PickedImages.single(image));
    _initPrefs();
  }

  /// Una o più immagini: con più di una si lavora a pagine, come un PDF.
  EditorController.images({
    required PickedImages images,
    required this.preferences,
    this.settings = const CutAnimationSettings(),
    this.exporter = const ExportService(),
  }) {
    _openImages(images);
    _initPrefs();
  }

  EditorController.pdf({
    required PdfSession session,
    required this.preferences,
    this.settings = const CutAnimationSettings(),
    this.exporter = const ExportService(),
  }) {
    _openPdf(session);
    _initPrefs();
  }

  /// Pagine PDF già pronte, senza documento sorgente (per i test).
  @visibleForTesting
  EditorController.pdfPages({
    required this.pages,
    required this.preferences,
    this.settings = const CutAnimationSettings(),
    this.exporter = const ExportService(),
  }) {
    kind = DocumentKind.pdf;
    _pdfPageTotal = pages.length;
    _resetView();
    _initPrefs();
  }

  final AppPreferences preferences;
  final CutAnimationSettings settings;
  final ExportService exporter;

  /// Notifica i ridisegni durante l'animazione senza ricostruire i widget.
  final ValueNotifier<int> frameTick = ValueNotifier(0);

  late DocumentKind kind;

  /// Le immagini aperte, una per pagina (vuota per i PDF).
  List<ImageFile> images = [];
  PdfSession? pdf;
  List<EditorPage> pages = [];
  int pageIndex = 0;

  bool smashEnabled = true;

  /// Diventa vero quando i frame di SMASH sono caricati.
  bool smashAvailable = false;

  /// Punto del colpo della skin in uso.
  Offset impactAnchor = SmashSprite.impactAnchor;

  /// Impaginazione proposta per le pagine appena tagliate.
  PdfLayoutMode layoutSuggestion = PdfLayoutMode.top;

  bool _selectionSuppressed = false;
  bool _reappearAfterRobot = false;
  CutAnimation? animation;
  Timer? _reappear;
  bool busyExporting = false;
  bool _disposed = false;

  // pannello Layout PDF
  bool layoutPanelOpen = false;
  PageLayout? previewLayout;

  /// Casella "Usa questo layout anche per le prossime pagine".
  bool layoutForNext = false;

  /// Layout scelto per le prossime pagine tagliate: vale da quando lo si
  /// sceglie in poi, le pagine già fatte non cambiano. `null` = si chiede
  /// ogni volta. Con Personalizza posizione il pannello si riapre comunque,
  /// perché ogni pagina ha un contenuto diverso.
  PageLayout? nextPagesLayout;

  // Personalizza posizione
  bool positioning = false;
  Offset positionOffset = Offset.zero;

  double zoom = 1;
  Offset pan = Offset.zero;
  Size viewportSize = Size.zero;
  double devicePixelRatio = 1;

  /// Pezzo della pagina reso ad alta definizione per lo zoom.
  ZoomPatch? zoomPatch;
  Timer? _patchTimer;
  int _patchGen = 0;
  Object? _patchKey;

  Timer? _saveTimer;
  Object? _saveKey;
  LineHandle? draggingHandle;

  final List<int> _recentPages = [];
  final Set<int> _rendering = {};
  Object? renderError;

  void _initPrefs() {
    smashEnabled = preferences.smashEnabled;
    layoutSuggestion = preferences.layoutSuggestion;
  }

  // --- lettura dello stato -------------------------------------------------

  bool get isPdf => kind == DocumentKind.pdf;

  /// Più pagine da scorrere: un PDF o un gruppo di immagini.
  bool get hasPages => pages.length > 1;
  bool get multiImage => !isPdf && images.length > 1;
  EditorPage get page => pages[pageIndex];
  bool get pageReady => page.isReady;
  int get pageCount => pages.length;
  StripDocument get doc => page.doc;
  DocSource get view => page.view;
  SelectionState get selection => page.selection;
  set selection(SelectionState s) => page.selection = s;

  bool get _modal => layoutPanelOpen || positioning;
  bool get isCutting => animation != null && !animation!.committed;
  bool get isAnimating => animation != null;
  bool get canUndo => page.history.canUndo && !isCutting && !_modal;
  bool get canRedo => page.history.canRedo && !isCutting && !_modal;
  bool get canNavigate => !isCutting && !_modal && !busyExporting;

  /// La selezione è visibile (non nascosta dall'utente né in attesa).
  bool get selectionVisible =>
      pageReady &&
      !octoMode &&
      selection.isVisible &&
      !_selectionSuppressed &&
      !_modal;
  CutOrientation get layoutOrientation => selection.mode ?? selection.lastMode;

  bool get canCut =>
      selectionVisible && !isCutting && !busyExporting && _pendingCut() != null;

  /// A e B prendono tutta la pagina: non è un taglio (non resterebbe nulla),
  /// ma il pulsante resta attivo per proporre di togliere la pagina.
  bool get selectsWholePage {
    if (!selectionVisible || isCutting || busyExporting) return false;
    final mode = selection.mode;
    final pair = selection.active;
    if (mode == null || pair == null) return false;
    final length = doc.lengthFor(mode);
    final b = _cutBounds()!;
    return b.$1 <= 0 && b.$2 >= length;
  }

  /// Il pulsante "Rimuovi porzione" si può toccare.
  bool get canPressCut => canCut || selectsWholePage;

  /// Foglio attuale: per le immagini coincide con il contenuto.
  PageFrame get frame {
    final override = positioning
        ? PageLayout(PdfLayoutMode.custom, positionOffset)
        : previewLayout;
    return page.frame(layoutSuggestion, override: override);
  }

  ViewportTransform transformFor(PageFrame f) => ViewportTransform(
    viewport: viewportSize,
    content: f.size,
    gutters: Gutters.forOrientation(layoutOrientation),
    zoom: zoom,
    pan: pan,
  ).clamped();

  ViewportTransform get transform => transformFor(frame);

  /// Rettangolo a schermo del contenuto (dentro il foglio, per i PDF).
  Rect get contentScreenRect => transform.regionToScreen(frame.contentRect);

  Offset contentToScreen(Offset p) =>
      transform.contentToScreen(p + frame.contentOffset);
  Offset screenToContent(Offset s) =>
      transform.screenToContent(s) - frame.contentOffset;

  // --- documento -----------------------------------------------------------

  void _openImages(PickedImages picked) {
    kind = DocumentKind.image;
    images = List.of(picked.files);
    pdf = null;
    pages = [
      for (var i = 0; i < images.length; i++)
        EditorPage(
          index: i,
          widthPx: images[i].width,
          heightPx: images[i].height,
          image: i < picked.decoded.length ? picked.decoded[i] : null,
        ),
    ];
    _resetView();
    for (var i = 0; i < pages.length; i++) {
      if (pages[i].isReady) _touch(i);
    }
  }

  void _openPdf(PdfSession session) {
    kind = DocumentKind.pdf;
    images = [];
    pdf = session;
    pages = session.createPages();
    _pdfPageTotal = pages.length;
    _resetView();
    _ensureRendered(0);
  }

  void _resetView() {
    pageIndex = 0;
    _recentPages.clear();
    _selectionSuppressed = false;
    layoutPanelOpen = false;
    previewLayout = null;
    positioning = false;
    zoom = 1;
    pan = Offset.zero;
  }

  void _closeCurrent() {
    _cancelAnimation();
    for (final p in pages) {
      p.evict();
    }
    final old = pdf;
    if (old != null) old.dispose();
  }

  void replaceWithImage(LoadedImage image) =>
      replaceWithImages(PickedImages.single(image));

  void replaceWithImages(PickedImages picked) {
    _closeCurrent();
    _openImages(picked);
    notifyListeners();
  }

  void replaceWithPdf(PdfSession session) {
    _closeCurrent();
    _openPdf(session);
    notifyListeners();
  }

  void setViewportSize(Size s) => viewportSize = s;

  // --- pagine di immagini: aggiungere e togliere -----------------------------

  bool get _canEditPages => canNavigate && !isAnimating;
  int get imagesRoom => ImageLoader.maxImages - images.length;
  bool get canAddImages => !isPdf && _canEditPages && imagesRoom > 0;

  /// Si può togliere la pagina corrente (ne resta sempre almeno una).
  bool get canRemovePage => _canEditPages && pages.length > 1;

  /// Pagine del PDF originale (anche quelle tolte).
  int _pdfPageTotal = 0;

  /// Numeri delle pagine del PDF originale tolte dal documento.
  List<int> get removedPdfPages {
    if (!isPdf) return const [];
    final present = {for (final p in pages) p.index};
    return [
      for (var i = 0; i < _pdfPageTotal; i++)
        if (!present.contains(i)) i,
    ];
  }

  /// Aggiunge immagini in fondo, senza toccare quelle già aperte e i loro
  /// tagli, e porta alla prima aggiunta.
  void addImages(PickedImages picked) {
    if (isPdf || picked.length == 0) {
      for (final d in picked.decoded) {
        d?.dispose();
      }
      return;
    }
    _cancelAnimation();
    final first = images.length;
    images = [...images, ...picked.files];
    for (var k = 0; k < picked.length; k++) {
      final f = picked.files[k];
      pages.add(
        EditorPage(
          index: first + k,
          widthPx: f.width,
          heightPx: f.height,
          image: k < picked.decoded.length ? picked.decoded[k] : null,
        ),
      );
    }
    for (var i = first; i < pages.length; i++) {
      if (pages[i].isReady) _touch(i);
    }
    _showPage(first);
    notifyListeners();
  }

  /// Toglie la pagina corrente dal documento (ne resta almeno una). Le
  /// pagine dei PDF tengono il loro numero originale, che serve per
  /// renderle ed esportarle; le immagini si rinumerano.
  void removeCurrentPage() {
    if (!canRemovePage) return;
    _cancelAnimation();
    final i = pageIndex;
    pages.removeAt(i).evict();
    if (!isPdf) {
      images = [...images]..removeAt(i);
      for (var k = 0; k < pages.length; k++) {
        pages[k].index = k;
      }
    }
    // la memoria delle pagine recenti si ricostruisce con i nuovi numeri
    _recentPages.clear();
    _rendering.clear();
    for (var k = 0; k < pages.length; k++) {
      if (pages[k].isReady) _recentPages.add(k);
    }
    _showPage(i.clamp(0, pages.length - 1));
    notifyListeners();
  }

  bool canMovePage(int delta) {
    final j = pageIndex + delta;
    return _canEditPages && j >= 0 && j < pages.length;
  }

  /// Sposta la pagina corrente di [delta] posti (-1 indietro, +1 avanti):
  /// cambia l'ordine nel documento salvato. Si resta sulla pagina spostata.
  void movePage(int delta) {
    if (!canMovePage(delta)) return;
    _cancelAnimation();
    final i = pageIndex, j = i + delta;
    final moved = pages.removeAt(i);
    pages.insert(j, moved);
    if (!isPdf) {
      final f = images[i];
      images = [...images]
        ..removeAt(i)
        ..insert(j, f);
      for (var k = 0; k < pages.length; k++) {
        pages[k].index = k;
      }
    }
    _recentPages.clear();
    _rendering.clear();
    for (var k = 0; k < pages.length; k++) {
      if (pages[k].isReady) _recentPages.add(k);
    }
    pageIndex = j;
    if (!page.isReady) _ensureRendered(j);
    notifyListeners();
  }

  /// Ordine delle pagine del PDF (numeri originali), se è cambiato.
  List<int> get pdfPageOrder {
    if (!isPdf) return const [];
    final order = [for (final p in pages) p.index];
    for (var k = 1; k < order.length; k++) {
      if (order[k] < order[k - 1]) return order;
    }
    return const [];
  }

  void _showPage(int i) {
    pageIndex = i;
    zoom = 1;
    pan = Offset.zero;
    if (page.isReady) {
      _touch(i);
    } else {
      _ensureRendered(i);
    }
    if (i + 1 < pages.length) _ensureRendered(i + 1);
  }

  // --- pagine PDF ------------------------------------------------------------

  /// Prepara i pixel di una pagina: resa del PDF oppure decodifica
  /// dell'immagine dal suo file.
  Future<void> _ensureRendered(int i) async {
    final session = pdf;
    final files = images;
    if (session == null && files.isEmpty) return;
    if (pages[i].isReady || _rendering.contains(i)) return;
    _rendering.add(i);
    final target = pages[i];
    try {
      final ui.Image img;
      if (session != null) {
        img = await session.render(target);
      } else {
        final f = files[i];
        img = (await ImageLoader.decode(f.bytes!, f.name)).image;
      }
      if (_disposed ||
          !identical(pdf, session) ||
          !identical(images, files) ||
          pages.length <= i ||
          !identical(pages[i], target)) {
        img.dispose();
        return;
      }
      target.attach(img);
      renderError = null;
      _touch(i);
    } catch (e) {
      renderError = e;
    } finally {
      _rendering.remove(i);
      if (!_disposed) notifyListeners();
    }
  }

  /// Pagine rese tenute in memoria (nel browser la memoria è poca); le
  /// altre si rifanno al bisogno.
  static const int keptPages = kIsWeb ? 2 : 3;

  void _touch(int i) {
    _recentPages
      ..remove(i)
      ..add(i);
    while (_recentPages.length > keptPages) {
      final victim = _recentPages.removeAt(0);
      if (victim != pageIndex && !identical(animation?.page, pages[victim])) {
        pages[victim].evict();
      }
    }
  }

  void goToPage(int i) {
    if (!hasPages ||
        !canNavigate ||
        i < 0 ||
        i >= pages.length ||
        i == pageIndex) {
      return;
    }
    _cancelAnimation();
    // i rettangoli non ancora confermati restano sulla loro pagina: si perdono
    octoRects.clear();
    octoSelected = null;
    // prepara anche la pagina successiva
    _showPage(i);
    notifyListeners();
  }

  // --- selezione -----------------------------------------------------------

  void tapOrientation(CutOrientation o) {
    if (isCutting || _modal || !pageReady) return;
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
    _dragTrail.clear();
    _dragClock
      ..reset()
      ..start();
    notifyListeners();
  }

  // --- precisione al rilascio -----------------------------------------------
  //
  // Quando il dito si stacca l'area di contatto si restringe e il telefono
  // legge il punto qualche pixel più in là: la linea "salta" proprio alla
  // fine. Si tiene la scia degli ultimi movimenti e, se il dito era quasi
  // fermo prima di staccarsi, al rilascio la linea torna dove era.
  final _dragTrail = <({int ms, double screen, double value})>[];
  final _dragClock = Stopwatch();

  /// Gli ultimi millisecondi prima del rilascio che possono essere "scatto".
  static const _liftWindowMs = 90;

  /// Prima dello scatto il dito era fermo: si è mosso al massimo di tanto
  /// (pixel dello schermo) nei 200 ms precedenti.
  static const _stillPx = 6.0;

  /// Lo scatto finale è piccolo: oltre questa distanza è un movimento voluto.
  static const _maxLiftPx = 28.0;

  /// Linea da ripristinare al rilascio, o `null` se va bene dov'è.
  @visibleForTesting
  static double? settledValue(
    List<({int ms, double screen, double value})> trail,
    int upMs,
  ) {
    if (trail.length < 2) return null;
    final cut = upMs - _liftWindowMs;
    // ultima posizione prima della finestra dello scatto
    final before = trail.lastWhere(
      (s) => s.ms <= cut,
      orElse: () => trail.first,
    );
    if (before.ms > cut) return null;
    final last = trail.last;
    if (last.ms <= cut) return null; // nessun movimento alla fine
    if ((last.screen - before.screen).abs() > _maxLiftPx) return null;
    // il dito era fermo prima dello scatto?
    final calm = trail.where((s) => s.ms > cut - 200 && s.ms <= cut);
    for (final s in calm) {
      if ((s.screen - before.screen).abs() > _stillPx) return null;
    }
    return before.value == last.value ? null : before.value;
  }

  void dragLineTo(Offset viewportPos) {
    final h = draggingHandle;
    final mode = selection.mode;
    if (h == null || mode == null) return;
    final c = screenToContent(viewportPos);
    final len = doc.lengthFor(mode);
    final v = (mode == CutOrientation.horizontal ? c.dy : c.dx)
        .clamp(0, len)
        .roundToDouble();
    final pair = selection.lines[mode]!;
    selection = selection.withLines(
      mode,
      h == LineHandle.a ? pair.withA(v) : pair.withB(v),
    );
    _dragTrail.add((
      ms: _dragClock.elapsedMilliseconds,
      screen: mode == CutOrientation.horizontal
          ? viewportPos.dy
          : viewportPos.dx,
      value: v,
    ));
    if (_dragTrail.length > 60) _dragTrail.removeAt(0);
    notifyListeners();
  }

  // --- OctoSmash ---------------------------------------------------------------
  //
  // Tocco lungo su "Rimuovi porzione": si entra nella modalità OctoSmash.
  // I rettangoli bianchi e neri si mettono, si spostano, si ridimensionano e
  // si ruotano; "Fatto" li spruzza d'inchiostro (un passo della cronologia,
  // annullabile con Undo una volta tornati a SMASH).

  bool octoMode = false;
  final List<OctoRect> octoRects = [];
  int? octoSelected;

  /// Mentre si ruota un rettangolo compaiono le guide tratteggiate.
  bool octoRotating = false;

  /// Spruzzo in corso (per l'animazione): rettangoli e inizio.
  List<OctoRect>? octoSplash;
  int octoSplashStart = 0;

  /// OctoSmash sveglio: spruzza con l'animazione e riempie i litri. Spento
  /// l'inchiostro si posa subito, senza animazione e senza litri.
  late bool octoEnabled = preferences.octoEnabled;

  void setOcto(bool on) {
    octoEnabled = on;
    preferences.setOctoEnabled(on);
    notifyListeners();
  }

  /// Durata dello spruzzo in corso (breve se OctoSmash dorme).
  int octoSplashDuration = octoSplashMs;

  /// Inizio dell'animazione di OctoSmash dopo "Fatto" (0 = ferma).
  int octoAnimStart = 0;
  bool get octoAnimating => octoAnimStart != 0;

  /// Tempi dell'animazione (10 fotogrammi al secondo come SMASH): lo spruzzo
  /// parte col fotogramma 6 (SPLASH!) e l'inchiostro si posa subito dopo.
  static const octoFrameMs = 100;
  static const octoSplashAtMs = 500;
  static const octoSplashMs = 550;
  static const octoAnimMs = 18 * octoFrameMs + 200;

  /// Chiamata a ogni "Fatto" con i litri spruzzati di ogni colore.
  void Function(double litres)? onInk;

  OctoRect? get octoCurrent =>
      octoSelected == null ? null : octoRects[octoSelected!];

  bool get canEnterOcto =>
      pageReady && !isCutting && !busyExporting && !_modal && !octoMode;

  void enterOcto() {
    if (!canEnterOcto) return;
    octoMode = true;
    octoRects.clear();
    octoSelected = null;
    notifyListeners();
  }

  void exitOcto() {
    if (!octoMode) return;
    octoMode = false;
    octoRects.clear();
    octoSelected = null;
    octoRotating = false;
    octoPicking = false;
    octoPickAt = null;
    notifyListeners();
  }

  /// Un rettangolo nuovo al centro di quello che si vede.
  void addOctoRect({required int color, Offset? at}) {
    if (!octoMode || !pageReady) return;
    final d = doc;
    final mid = at ?? screenToContent(viewportSize.center(Offset.zero));
    final center = Offset(
      mid.dx.clamp(0, d.width.toDouble()),
      mid.dy.clamp(0, d.height.toDouble()),
    );
    // grande metà della larghezza visibile, alto un quinto
    final visW = viewportSize.width / transform.scale;
    final w = math.max(OctoRect.minSide, math.min(d.width * .6, visW * .5));
    final h = math.max(OctoRect.minSide, w * .25);
    octoRects.add(OctoRect(center: center, w: w, h: h, color: color));
    octoSelected = octoRects.length - 1;
    notifyListeners();
  }

  void selectOcto(int? i) {
    octoSelected = i;
    notifyListeners();
  }

  void deleteSelectedOcto() {
    final i = octoSelected;
    if (i == null) return;
    octoRects.removeAt(i);
    octoSelected = null;
    notifyListeners();
  }

  void octoChanged({bool rotating = false}) {
    octoRotating = rotating;
    notifyListeners();
  }

  void rotateSelectedOcto(double deg) {
    final r = octoCurrent;
    if (r == null) return;
    r.rotateBy(deg);
    notifyListeners();
  }

  void straightenSelectedOcto() {
    final r = octoCurrent;
    if (r == null) return;
    r.angle = 0;
    notifyListeners();
  }

  /// "Fatto": breve spruzzo, poi l'inchiostro entra nel documento.
  void commitOcto() {
    if (!octoMode || octoRects.isEmpty || octoSplash != null || octoAnimating) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    octoSplash = List.of(octoRects);
    if (!octoEnabled) {
      // dorme: l'inchiostro si posa subito, senza OctoSmash
      octoSplashStart = now;
      octoSplashDuration = 220;
      octoSelected = null;
      octoRects.clear();
      notifyListeners();
      Timer(const Duration(milliseconds: 220), () => _applySplash(ink: false));
      return;
    }
    octoSplashDuration = octoSplashMs;
    octoAnimStart = now;
    octoSplashStart = now + octoSplashAtMs;
    octoSelected = null;
    octoRects.clear();
    notifyListeners();
    Timer(
      const Duration(milliseconds: octoSplashAtMs + octoSplashMs),
      _applySplash,
    );
    Timer(const Duration(milliseconds: octoAnimMs), () {
      if (_disposed) return;
      octoAnimStart = 0;
      notifyListeners();
    });
  }

  void _applySplash({bool ink = true}) {
    final rs = octoSplash;
    if (rs == null || _disposed) return;
    octoSplash = null;
    final p = page;
    final d = p.doc;
    double litres = 0;
    final fills = [
      for (final r in rs)
        r.toFill(
          Offset(
            _toOriginal(d.cols, r.center.dx, d.width),
            _toOriginal(d.rows, r.center.dy, d.height),
          ),
        ),
    ];
    for (final r in rs) {
      litres += r.area / 250000;
    }
    p.history.pushFills(fills);
    p.refreshView();
    // un solo contatore per tutti gli inchiostri
    if (ink) onInk?.call(litres);
    notifyListeners();
  }

  /// Da coordinata attuale a coordinata dell'originale (conserva la parte
  /// decimale, così il rettangolo non scivola di mezzo pixel).
  static double _toOriginal(IndexRuns runs, double v, int len) {
    final i = v.floor().clamp(0, len - 1);
    return runs.originalIndex(i) + (v - v.floor());
  }

  // --- pipetta ----------------------------------------------------------------

  /// La pipetta è pronta: il prossimo tocco sulla pagina prende un colore.
  bool octoPicking = false;

  /// Dove si trova il dito mentre si sceglie il colore (schermo).
  Offset? octoPickAt;

  /// Ultimi colori presi con la pipetta (il primo è il più recente).
  final List<int> pickedColors = [];

  void startPicking() {
    if (!octoMode || !pageReady || octoAnimating) return;
    octoPicking = true;
    octoPickAt = null;
    livePickColor = null;
    octoSelected = null;
    notifyListeners();
  }

  void cancelPicking() {
    if (!octoPicking) return;
    octoPicking = false;
    octoPickAt = null;
    notifyListeners();
  }

  /// Colore sotto il mirino in questo momento (si aggiorna mentre ci si
  /// muove), così si sa che colore si prende lasciando il dito.
  int? livePickColor;
  bool _sampling = false;

  void movePick(Offset screen) {
    if (!octoPicking) return;
    octoPickAt = screen;
    notifyListeners();
    _sampleLive();
  }

  Future<void> _sampleLive() async {
    if (_sampling) return;
    _sampling = true;
    try {
      Offset? done;
      // finché il dito si sposta, rileggi l'ultimo punto
      while (octoPicking && octoPickAt != null && octoPickAt != done) {
        done = octoPickAt;
        final o = contentToOriginal(screenToContent(done!));
        final color = o == null ? null : await _colorAt(o);
        if (_disposed || !octoPicking) return;
        if (color != null && color != livePickColor) {
          livePickColor = color;
          notifyListeners();
        }
      }
    } finally {
      _sampling = false;
    }
  }

  /// Punto del documento → punto dell'immagine originale della pagina.
  Offset? contentToOriginal(Offset content) {
    final d = doc;
    if (content.dx < 0 ||
        content.dy < 0 ||
        content.dx >= d.width ||
        content.dy >= d.height) {
      return null;
    }
    return Offset(
      _toOriginal(d.cols, content.dx, d.width),
      _toOriginal(d.rows, content.dy, d.height),
    );
  }

  ui.Image? get pageImage => page.image;

  /// Dito alzato: prende il colore sotto il mirino e mette lì il rettangolo.
  Future<void> finishPick() async {
    final at = octoPickAt;
    octoPicking = false;
    octoPickAt = null;
    notifyListeners();
    if (at == null || !octoMode) return;
    final content = screenToContent(at);
    final o = contentToOriginal(content);
    if (o == null) return;
    final color = await _colorAt(o);
    if (color == null || _disposed) return;
    pickedColors
      ..remove(color)
      ..insert(0, color);
    if (pickedColors.length > 8) pickedColors.removeLast();
    addOctoRect(color: color, at: content);
  }

  /// Colore di un pixel dell'originale (compreso l'inchiostro già messo).
  Future<int?> _colorAt(Offset o) async {
    for (final f in page.history.fills.reversed) {
      if (f.contains(o.dx, o.dy)) return f.color;
    }
    final img = page.image;
    if (img == null) return null;
    final rec = ui.PictureRecorder();
    ui.Canvas(rec).drawImageRect(
      img,
      Rect.fromLTWH(o.dx.floorToDouble(), o.dy.floorToDouble(), 1, 1),
      const Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..filterQuality = ui.FilterQuality.none,
    );
    final pic = rec.endRecording();
    final one = await pic.toImage(1, 1);
    pic.dispose();
    final data = await one.toByteData(format: ui.ImageByteFormat.rawRgba);
    one.dispose();
    if (data == null) return null;
    return 0xFF000000 |
        (data.getUint8(0) << 16) |
        (data.getUint8(1) << 8) |
        data.getUint8(2);
  }

  // --- precisione al pixel ---------------------------------------------------

  /// Linea che si sta regolando con le frecce (si illumina la sua maniglia).
  LineHandle? fineHandle;

  /// Sposta la linea [h] di [step] pixel del documento (+1 giù/destra,
  /// -1 su/sinistra). `false` se è già al bordo.
  bool nudgeLine(LineHandle h, int step) {
    final mode = selection.mode;
    if (mode == null || isCutting || !selectionVisible) return false;
    final pair = selection.lines[mode];
    if (pair == null) return false;
    final len = doc.lengthFor(mode).toDouble();
    final cur = h == LineHandle.a ? pair.a : pair.b;
    final v = (cur.roundToDouble() + step).clamp(0.0, len);
    fineHandle = h;
    if (v == cur) {
      notifyListeners();
      return false;
    }
    selection = selection.withLines(
      mode,
      h == LineHandle.a ? pair.withA(v) : pair.withB(v),
    );
    notifyListeners();
    return true;
  }

  void endNudge() {
    if (fineHandle == null) return;
    fineHandle = null;
    notifyListeners();
  }

  void endLineDrag() {
    final h = draggingHandle;
    if (h == null) return;
    final mode = selection.mode;
    final back = settledValue(_dragTrail, _dragClock.elapsedMilliseconds);
    if (mode != null && back != null) {
      final pair = selection.lines[mode]!;
      selection = selection.withLines(
        mode,
        h == LineHandle.a ? pair.withA(back) : pair.withB(back),
      );
    }
    _dragTrail.clear();
    _dragClock.stop();
    draggingHandle = null;
    notifyListeners();
  }

  // --- zoom e spostamento --------------------------------------------------

  @override
  void notifyListeners() {
    _watchZoomPatch();
    _watchAutosave();
    super.notifyListeners();
  }

  // --- salvataggio automatico del lavoro -------------------------------------

  // il lavoro si riprende per un PDF o per un'immagine singola
  String? get _workName =>
      isPdf ? pdf?.name : (images.length == 1 ? images.first.name : null);
  int? get _workSize => isPdf
      ? pdf?.fileSize
      : (images.length == 1 ? images.first.bytes?.length : null);

  void _watchAutosave() {
    if (_disposed || _workName == null || _workSize == null) return;
    if (animation != null && !animation!.committed) return;
    final key = Object.hashAll([
      pageIndex,
      nextPagesLayout,
      pages.length,
      for (final p in pages) p.index,
      for (final p in pages) Object.hash(p.history.cursor, p.history.length),
    ]);
    if (key == _saveKey) return;
    _saveKey = key;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _autosave);
  }

  void _autosave() {
    final name = _workName, size = _workSize;
    if (name == null || size == null) return;
    final w = SavedWork.capture(
      isPdf: isPdf,
      name: name,
      size: size,
      pageIndex: pageIndex,
      pages: pages,
      nextPagesLayout: nextPagesLayout?.mode,
      removed: removedPdfPages,
      order: pdfPageOrder,
    );
    if (w != null) {
      preferences.setSavedWork(w.encode());
      WorkFileStore.instance.promote(name: name, size: size, isPdf: isPdf);
      return;
    }
    // tutto annullato: si toglie il salvataggio, se era di questo file
    final old = SavedWork.decode(preferences.savedWork);
    if (old != null && old.matches(isPdf: isPdf, name: name, size: size)) {
      preferences.clearSavedWork();
      WorkFileStore.instance.clear();
    }
  }

  /// Riprende un lavoro salvato sul file appena riaperto.
  void restoreWork(SavedWork w) {
    w.replayOn(pages);
    if (isPdf && w.removed.isNotEmpty) {
      final gone = w.removed.toSet();
      final keep = [
        for (final p in pages)
          if (!gone.contains(p.index)) p,
      ];
      if (keep.isNotEmpty) {
        for (final p in pages) {
          if (gone.contains(p.index)) p.evict();
        }
        pages = keep;
        _recentPages.clear();
        for (var k = 0; k < pages.length; k++) {
          if (pages[k].isReady) _recentPages.add(k);
        }
        pageIndex = 0;
        if (!page.isReady) _ensureRendered(0);
      }
    }
    if (isPdf && w.order.isNotEmpty) {
      final pos = {for (var k = 0; k < w.order.length; k++) w.order[k]: k};
      pages.sort(
        (a, b) => (pos[a.index] ?? 1 << 20).compareTo(pos[b.index] ?? 1 << 20),
      );
      _recentPages.clear();
      for (var k = 0; k < pages.length; k++) {
        if (pages[k].isReady) _recentPages.add(k);
      }
    }
    for (final p in pages) {
      p.selection = SelectionState.initial(
        width: p.doc.width,
        height: p.doc.height,
      );
    }
    final next = w.nextPagesLayout;
    nextPagesLayout = next == null ? null : PageLayout(next);
    final i = w.pageIndex.clamp(0, pages.length - 1);
    if (i != pageIndex) {
      pageIndex = i;
      if (page.isReady) {
        _touch(i);
      } else {
        _ensureRendered(i);
      }
    }
    notifyListeners();
  }

  /// Quando la vista si ferma per un attimo, la parte visibile si rende di
  /// nuovo ad alta definizione: la pagina intera resta leggera in memoria,
  /// ma ingrandendo il testo resta nitido.
  void _watchZoomPatch() {
    if (_disposed) return;
    final zp = zoomPatch;
    if (zp != null &&
        (!isPdf ||
            pages.isEmpty ||
            !identical(zp.page, page) ||
            !identical(zp.doc, doc))) {
      zp.dispose();
      zoomPatch = null;
    }
    if (!isPdf || pdf == null || pages.isEmpty) return;
    final key = Object.hash(
      pageIndex,
      identityHashCode(doc),
      zoom,
      pan,
      positioning,
      animation == null,
      viewportSize,
      previewLayout,
    );
    if (key == _patchKey) return;
    _patchKey = key;
    _patchGen++;
    _patchTimer?.cancel();
    _patchTimer = Timer(const Duration(milliseconds: 250), _buildZoomPatch);
  }

  Future<void> _buildZoomPatch() async {
    final session = pdf;
    if (_disposed || session == null || !pageReady) return;
    if (animation != null || positioning || viewportSize.isEmpty) return;
    // con gli inchiostri di OctoSmash niente pezzi ad alta risoluzione
    // (li coprirebbero)
    if (page.history.hasFills) return;
    final t = transform;
    final dpr = math.min(devicePixelRatio, kIsWeb ? 2.0 : 3.0);
    var factor = t.scale * dpr;
    final d = doc;
    final bounds = Rect.fromLTWH(0, 0, d.width.toDouble(), d.height.toDouble());
    var vis = Rect.fromPoints(
      screenToContent(Offset.zero),
      screenToContent(viewportSize.bottomRight(Offset.zero)),
    ).intersect(bounds);
    if (factor <= 1.1 || vis.width <= 0 || vis.height <= 0) {
      if (zoomPatch != null) {
        zoomPatch!.dispose();
        zoomPatch = null;
        super.notifyListeners();
      }
      return;
    }
    // un po' di margine intorno, per piccoli spostamenti
    vis = vis.inflate(vis.shortestSide * .15).intersect(bounds);
    vis = Rect.fromLTRB(
      vis.left.floorToDouble(),
      vis.top.floorToDouble(),
      vis.right.ceilToDouble(),
      vis.bottom.ceilToDouble(),
    );
    final maxPx = kIsWeb ? 4e6 : 8e6;
    final area = vis.width * vis.height;
    if (area * factor * factor > maxPx) factor = math.sqrt(maxPx / area);
    if (factor <= 1.1) return;
    final tiles = d.tiles(
      x0: vis.left.toInt(),
      y0: vis.top.toInt(),
      x1: vis.right.toInt(),
      y1: vis.bottom.toInt(),
    );
    if (tiles.length > 48) return;
    final gen = _patchGen;
    final pg = page;
    final pieces = <(Rect, ui.Image)>[];
    void drop() {
      for (final p in pieces) {
        p.$2.dispose();
      }
    }

    try {
      for (final tl in tiles) {
        final img = await session.renderRegion(
          pg,
          tl[0],
          tl[1],
          tl[4],
          tl[5],
          factor,
        );
        if (img == null) continue;
        pieces.add((
          Rect.fromLTWH(
            tl[2].toDouble(),
            tl[3].toDouble(),
            tl[4].toDouble(),
            tl[5].toDouble(),
          ),
          img,
        ));
        if (gen != _patchGen || _disposed) {
          drop();
          return;
        }
      }
    } catch (_) {
      drop();
      return;
    }
    if (gen != _patchGen || _disposed || !identical(pg, page)) {
      drop();
      return;
    }
    zoomPatch?.dispose();
    zoomPatch = ZoomPatch(pg, d, pieces);
    super.notifyListeners();
  }

  double _zoom0 = 1;
  Offset _pan0 = Offset.zero;
  Offset _focal0 = Offset.zero;
  Offset _lastFocal = Offset.zero;

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
    _lastFocal = focal;
  }

  void gestureUpdate(Offset focal, double scale) {
    if (positioning) {
      // Personalizza posizione: il dito sposta l'intero contenuto, senza
      // ridimensionarlo
      final delta = (focal - _lastFocal) / transform.scale;
      _lastFocal = focal;
      positionOffset = PageFrame.clampOffset(
        positionOffset + delta,
        page.originalSize,
        frame.contentSize,
      );
      notifyListeners();
      return;
    }
    if (draggingHandle != null || isCutting || !pageReady) return;
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

  /// Spessore delle linee rosse A e B sullo schermo (editor_viewport.dart).
  /// (Nei test che verificano misure esatte tra i centri si mette a 0.)
  static double selectionLineWidth = 3.0;

  /// La fascia che sparisce, in pixel del documento: tutto ciò che è tra le
  /// linee rosse **comprese le linee stesse**, cioè quello che l'occhio vede
  /// coperto. Ogni linea è larga [selectionLineWidth] sullo schermo: si
  /// allarga di mezza linea verso l'esterno, allo zoom attuale, e si
  /// arrotonda sempre verso l'esterno.
  (double, double)? _cutBounds() {
    final mode = selection.mode;
    final pair = selection.active;
    if (mode == null || pair == null) return null;
    final length = doc.lengthFor(mode).toDouble();
    final horizontal = mode == CutOrientation.horizontal;
    double screen(double v) => horizontal
        ? contentToScreen(Offset(0, v)).dy
        : contentToScreen(Offset(v, 0)).dx;
    final perPx = (screen(1) - screen(0)).abs();
    final half = perPx > 0 ? (selectionLineWidth / 2) / perPx : 0.0;
    final lo = (pair.a < pair.b ? pair.a : pair.b) - half;
    final hi = (pair.a < pair.b ? pair.b : pair.a) + half;
    return (
      lo.floorToDouble().clamp(0.0, length),
      hi.ceilToDouble().clamp(0.0, length),
    );
  }

  CutOperation? _pendingCut() {
    final mode = selection.mode;
    final b = _cutBounds();
    if (mode == null || b == null) return null;
    return CutOperation.fromLines(
      orientation: mode,
      a: b.$1,
      b: b.$2,
      length: doc.lengthFor(mode),
    );
  }

  /// Avvia il taglio. Restituisce `false` se la selezione non è valida.
  bool removePortion() {
    if (!canCut) return false;
    final op = _pendingCut()!;
    final p = page;
    final img = p.image!;
    final frame0 = frame;
    final t0 = transformFor(frame0);
    final afterDoc = doc.apply(op);
    final after = DocSource.build(img, afterDoc, fills: p.history.fills);
    final firstCut = isPdf && !p.history.hasCuts && p.history.layout == null;
    final layout1 = isPdf
        ? (p.history.layout ?? PageLayout(layoutSuggestion))
        : null;
    final frame1 = PageFrame.compute(
      original: p.originalSize,
      content: Size(afterDoc.width.toDouble(), afterDoc.height.toDouble()),
      layout: layout1,
    );
    final t1 = t0.copyWith(content: frame1.size);
    final smash = smashEnabled && smashAvailable;
    final impact = _impactPoint(t0, frame0, op);
    final cross = op.orientation == CutOrientation.horizontal
        ? doc.width
        : doc.height;
    final mmPerPx = isPdf
        ? RubbleMath.pdfMmPerPt / p.pxPerPoint
        : RubbleMath.imageMmPerPx;
    final stripSrc = op.orientation == CutOrientation.horizontal
        ? Rect.fromLTWH(
            0,
            op.start.toDouble(),
            doc.width.toDouble(),
            op.removed.toDouble(),
          )
        : Rect.fromLTWH(
            op.start.toDouble(),
            0,
            op.removed.toDouble(),
            doc.height.toDouble(),
          );
    animation = CutAnimation(
      page: p,
      op: op,
      before: p.view,
      after: after,
      frame0: frame0,
      frame1: frame1,
      t0: t0,
      t1: t1,
      timeline: CutTimeline(settings: settings, smash: smash),
      placement: smash
          ? SmashPlacement(
              viewport: viewportSize,
              impact: impact,
              robotHeight: viewportSize.width * settings.robotHeightFraction,
              anchor: impactAnchor,
            )
          : null,
      shards: smash ? _makeShards(t0, frame0, op, impact) : const [],
      firstCutOnPdfPage: firstCut,
      stripRect: t0
          .regionToScreen(stripSrc.shift(frame0.contentOffset))
          .intersect(Offset.zero & viewportSize),
      rubbleKg: smash ? RubbleMath.kgOf(op, cross, mmPerPx) : 0,
    );
    _selectionSuppressed = true;
    notifyListeners();
    return true;
  }

  /// Epicentro: a metà tra A e B sull'asse del taglio, al centro della parte
  /// visibile del contenuto sull'altro asse.
  Offset _impactPoint(ViewportTransform t, PageFrame f, CutOperation op) {
    final content = t.regionToScreen(f.contentRect);
    final visible = content.intersect(Offset.zero & viewportSize);
    final mid = (op.start + op.end) / 2;
    if (op.orientation == CutOrientation.horizontal) {
      final y = t.contentToScreen(Offset(0, f.contentOffset.dy + mid)).dy;
      return Offset(
        visible.center.dx,
        y.clamp(0, viewportSize.height).toDouble(),
      );
    }
    final x = t.contentToScreen(Offset(f.contentOffset.dx + mid, 0)).dx;
    return Offset(x.clamp(0, viewportSize.width).toDouble(), visible.center.dy);
  }

  List<Shard> _makeShards(
    ViewportTransform t,
    PageFrame f,
    CutOperation op,
    Offset impact,
  ) {
    final w = doc.width.toDouble(), h = doc.height.toDouble();
    final src = op.orientation == CutOrientation.horizontal
        ? Rect.fromLTWH(0, op.start.toDouble(), w, op.removed.toDouble())
        : Rect.fromLTWH(op.start.toDouble(), 0, op.removed.toDouble(), h);
    final dst = t.regionToScreen(src.shift(f.contentOffset));
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
      if (_reappearAfterRobot) {
        _reappearAfterRobot = false;
        _selectionSuppressed = false;
      }
      notifyListeners();
    }
    frameTick.value++;
  }

  void _commit(CutAnimation a) {
    a.committed = true;
    final p = a.page;
    p.history.push(a.op);
    p.adoptView(a.after);
    zoom = a.t1.zoom;
    pan = a.t1.pan;
    p.selection = p.selection.afterCut(
      a.op.orientation,
      width: p.doc.width,
      height: p.doc.height,
    );
    _reappear?.cancel();
    final auto = nextPagesLayout;
    if (a.firstCutOnPdfPage &&
        auto != null &&
        auto.mode != PdfLayoutMode.custom) {
      // layout già scelto per le prossime pagine: niente pannello
      p.history.pushLayout(auto);
    }
    if (a.firstCutOnPdfPage &&
        (auto == null || auto.mode == PdfLayoutMode.custom)) {
      // primo taglio della pagina: si sceglie l'impaginazione; la nuova
      // selezione aspetta che il pannello si chiuda
      layoutPanelOpen = true;
      layoutForNext = auto != null;
      previewLayout = auto ?? PageLayout(layoutSuggestion);
      if (previewLayout!.mode == PdfLayoutMode.custom) {
        previewLayout = PageLayout(PdfLayoutMode.custom, frame.contentOffset);
      }
    } else {
      // il conteggio parte solo ora, a ricongiungimento completato
      _reappear = Timer(settings.reappearDelay, () {
        // se SMASH è ancora in scena si aspetta che esca: una nuova
        // selezione (e un nuovo pugno) sopra di lui sembrava un difetto
        if (animation != null) {
          _reappearAfterRobot = true;
          return;
        }
        _selectionSuppressed = false;
        if (!_disposed) notifyListeners();
      });
    }
    notifyListeners();
  }

  void _cancelAnimation() {
    final a = animation;
    animation = null;
    _reappear?.cancel();
    _reappearAfterRobot = false;
    _selectionSuppressed = false;
    if (a != null) {
      if (!a.committed) a.after.dispose();
      if (a.committed) a.before.dispose();
    }
  }

  // --- cronologia ----------------------------------------------------------

  void undo() => _step(() => page.history.undo());
  void redo() => _step(() => page.history.redo());

  void _step(bool Function() move) {
    if (isCutting || _modal) return;
    _cancelAnimation();
    if (!move()) return;
    page.refreshView();
    selection = selection.ensureValid(width: doc.width, height: doc.height);
    pan = transform.pan;
    notifyListeners();
  }

  // --- impaginazione PDF -------------------------------------------------------

  void openLayoutPanel() {
    if (!isPdf || !canNavigate || !pageReady) return;
    _reappear?.cancel();
    layoutPanelOpen = true;
    layoutForNext = nextPagesLayout != null;
    previewLayout =
        page.effectiveLayout(layoutSuggestion) ?? PageLayout(layoutSuggestion);
    notifyListeners();
  }

  void setLayoutForNext(bool v) {
    if (!layoutPanelOpen) return;
    layoutForNext = v;
    notifyListeners();
  }

  /// Le pagine tagliate senza una scelta esplicita seguono il suggerimento:
  /// prima di cambiarlo le si fissa, così non cambiano da sole.
  void _freezeCutPages({EditorPage? except}) {
    for (final p in pages) {
      if (p != except && p.history.hasCuts && p.history.layout == null) {
        p.history.pushLayout(PageLayout(layoutSuggestion));
      }
    }
  }

  /// Anteprima di una modalità mentre il pannello è aperto.
  void previewLayoutMode(PdfLayoutMode m) {
    if (!layoutPanelOpen) return;
    previewLayout = m == PdfLayoutMode.custom
        ? PageLayout(m, frame.contentOffset)
        : PageLayout(m);
    notifyListeners();
  }

  /// Applica e continua alla pagina corrente (Centrato, In alto, Riduci
  /// pagina); con Personalizza posizione apre il trascinamento. Se la casella
  /// è spuntata, lo stesso layout vale per le prossime pagine tagliate.
  void applyLayout() {
    final l = previewLayout;
    if (!layoutPanelOpen || l == null) return;
    // la pagina corrente riceve la sua scelta qui sotto
    _freezeCutPages(except: page);
    nextPagesLayout = layoutForNext ? PageLayout(l.mode) : null;
    if (l.mode == PdfLayoutMode.custom) {
      startPositioning();
      return;
    }
    if (page.history.hasCuts && page.history.layout != l) {
      page.history.pushLayout(l);
    }
    layoutSuggestion = l.mode;
    preferences.setLayoutSuggestion(l.mode);
    _closePanel();
  }

  void dismissLayoutPanel() {
    if (!layoutPanelOpen) return;
    _freezeCutPages();
    _closePanel();
  }

  void _closePanel() {
    layoutPanelOpen = false;
    previewLayout = null;
    _selectionSuppressed = false;
    pan = transform.pan;
    notifyListeners();
  }

  void startPositioning() {
    if (!isPdf || !pageReady || !page.history.hasCuts) return;
    final start = frame.contentOffset;
    layoutPanelOpen = false;
    previewLayout = null;
    positioning = true;
    positionOffset = start;
    zoom = 1;
    pan = Offset.zero;
    notifyListeners();
  }

  void confirmPosition() {
    if (!positioning) return;
    final l = PageLayout(PdfLayoutMode.custom, positionOffset);
    if (page.history.layout != l) page.history.pushLayout(l);
    positioning = false;
    _selectionSuppressed = false;
    notifyListeners();
  }

  void cancelPositioning() {
    if (!positioning) return;
    positioning = false;
    _selectionSuppressed = false;
    notifyListeners();
  }

  // --- SMASH ----------------------------------------------------------------

  void setSmash(bool on) {
    smashEnabled = on;
    preferences.setSmashEnabled(on);
    notifyListeners();
  }

  // --- esportazione ---------------------------------------------------------

  /// Pixel di sistema di una pagina immagine (decodificata se serve).
  Future<ui.Image> _pixelsOf(int i) async {
    if (!pages[i].isReady) await _ensureRendered(i);
    final img = pages[i].image;
    if (img == null) throw StateError('Pagina ${i + 1} non leggibile');
    return img;
  }

  Future<ExportedFile> _exportPage(int i, {String? baseName}) =>
      exporter.buildFile(
        images[i],
        pages[i].doc,
        pixels: () => _pixelsOf(i),
        baseName: baseName,
        fills: pages[i].history.fills,
      );

  /// L'immagine della pagina corrente, nel formato in cui è stata caricata.
  Future<ExportedFile?> buildImageExport() =>
      _busy(() => _exportPage(pageIndex));

  /// Tutte le immagini, ognuna nel suo formato, numerate in ordine.
  Future<List<ExportedFile>?> buildImageExports() => _busy(() async {
    if (images.length == 1) return [await _exportPage(0)];
    final base = ExportService.baseFileName();
    final digits = images.length.toString().length.clamp(2, 3);
    return [
      for (var i = 0; i < images.length; i++)
        await _exportPage(
          i,
          baseName: '${base}_${(i + 1).toString().padLeft(digits, '0')}',
        ),
    ];
  });

  /// Le immagini come un unico PDF, una per pagina.
  Future<Uint8List?> buildImagesPdfExport() => _busy(
    () => buildImagesPdf([
      for (var i = 0; i < images.length; i++)
        ImagePdfPage(
          images[i],
          pages[i].doc,
          () => _pixelsOf(i),
          fills: pages[i].history.fills,
        ),
    ], exporter: exporter),
  );

  Future<Uint8List?> buildPdfExport() =>
      _busy(() => pdf!.export(pages, layoutSuggestion));

  Future<T?> _busy<T>(Future<T> Function() job) async {
    if (busyExporting) return null;
    busyExporting = true;
    notifyListeners();
    try {
      return await job();
    } finally {
      busyExporting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      _autosave();
    }
    _disposed = true;
    _patchTimer?.cancel();
    _patchGen++;
    zoomPatch?.dispose();
    zoomPatch = null;
    _closeCurrent();
    frameTick.dispose();
    super.dispose();
  }
}

/// Pezzi della pagina resi ad alta definizione, in pixel del documento.
class ZoomPatch {
  ZoomPatch(this.page, this.doc, this.pieces);
  final EditorPage page;
  final StripDocument doc;
  final List<(Rect, ui.Image)> pieces;

  void dispose() {
    for (final p in pieces) {
      p.$2.dispose();
    }
  }
}
