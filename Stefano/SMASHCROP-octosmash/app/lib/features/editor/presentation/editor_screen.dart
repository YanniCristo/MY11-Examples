import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/large_file_dialog.dart';
import '../../../core/widgets/password_dialog.dart';

import '../../../app/strings.dart';
import '../../ads/ads_tracker.dart';
import '../../notifications/notifications.dart';
import '../../premium/lifetime_sheet.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_menu.dart';
import '../../rubble/application/rubble_store.dart';
import '../../rubble/application/skin_assets.dart';
import '../../rubble/application/sound_fx.dart';
import '../../rubble/domain/skins.dart';
import '../../rubble/presentation/collection_screen.dart';
import '../../rubble/presentation/counter_bar.dart';
import '../../rubble/presentation/evolution_overlay.dart';
import '../../rubble/presentation/rubble_menu.dart';
import '../../rubble/presentation/rubble_overlay.dart';
import '../../rubble/presentation/skin_effects.dart';
import '../../export/export_service.dart';
import '../../export/web_share/web_share.dart' as web_share;
import '../../image_processing/services/image_loader.dart';
import '../../image_processing/services/web_pick/web_pick.dart';
import '../../pdf_processing/presentation/layout_panel.dart';
import '../../pdf_processing/services/pdf_loader.dart';
import '../../pdf_processing/services/pdf_service.dart';
import '../../settings/preferences.dart';
import '../../octo/domain/ink_fill.dart';
import '../../octo/presentation/ink_counter_bar.dart';
import '../../octo/presentation/octo_palette.dart';
import '../application/editor_controller.dart';
import '../application/saved_work.dart';
import '../domain/cut_operation.dart';
import '../domain/viewport_transform.dart';
import 'editor_viewport.dart';
import 'smash_toggle.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.preferences,
    this.images,
    this.pdf,
    this.restore,
  }) : assert((images == null) != (pdf == null));

  final AppPreferences preferences;
  final PickedImages? images;
  final PdfSession? pdf;

  /// Lavoro salvato da riprendere sul file appena aperto.
  final SavedWork? restore;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late final EditorController c;
  late final Ticker _ticker;
  final _imageLoader = ImageLoader();
  final _pdfLoader = const PdfLoader();
  final _shareKey = GlobalKey();
  List<ui.Image>? _frames;
  CutAnimation? _runningFor;
  String? _loadingLabel;

  // --- macerie ---
  final RubbleStore _rubble = RubbleStore.instance;
  SkinImages? _skinImgs;
  String? _loadedSkin;
  final _viewportKey = GlobalKey();
  final _headKey = GlobalKey();
  final _bottomKey = GlobalKey();

  /// Feste in attesa (evoluzioni e tappe): partono a taglio finito.
  final List<SkinDef> _pendingEvolutions = [];
  final List<String> _pendingMilestones = [];
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    c = widget.images != null
        ? EditorController.images(
            images: widget.images!,
            preferences: widget.preferences,
          )
        : EditorController.pdf(
            session: widget.pdf!,
            preferences: widget.preferences,
          );
    if (widget.restore != null) c.restoreWork(widget.restore!);
    // OctoSmash: i litri d'inchiostro vanno nel loro contatore
    c.onInk = (litres) =>
        _rubble.flag((s) => s.inkBlackMl += (litres * 1000).round());
    _ticker = createTicker(c.tick);
    c.addListener(_syncTicker);
    _rubble.addListener(_onRubble);
    _loadSkin();
  }

  /// Carica le immagini dello SMASH in uso (e le ricarica se cambia).
  void _loadSkin() {
    final skin = _rubble.skin;
    if (_loadedSkin == skin.id) return;
    _loadedSkin = skin.id;
    if (_rubble.sound) SoundFx.instance.prepare(skin);
    SkinImages.load(skin)
        .then((imgs) {
          if (!mounted || _rubble.skinId != skin.id) return;
          setState(() {
            _skinImgs = imgs;
            _frames = imgs.frames;
          });
          c.impactAnchor = skin.impactAnchor;
          c.smashAvailable = true;
        })
        .catchError((_) {
          _loadedSkin = null;
        });
  }

  void _onRubble() {
    if (_rubble.skinId != _loadedSkin) _loadSkin();
    if (mounted) setState(() {});
  }

  void _onImpact(CutAnimation a) {
    if (_rubble.sound) SoundFx.instance.hit(_skinImgs?.skin ?? _rubble.skin);
    if (_rubble.haptics) SoundFx.punch();
  }

  void _onArrive(CutAnimation a) {
    final gain = _rubble.add(a.rubbleKg);
    if (_rubble.sound) SoundFx.instance.pling();
    if (_rubble.haptics) SoundFx.tick();
    if (gain.evolutions.isNotEmpty) AdsTracker.instance.firstEvolution();
    _pendingEvolutions.addAll(gain.evolutions);
    _pendingMilestones.addAll(gain.milestones);
    if (!_rubble.collectionHintShown) {
      _rubble.flag((s) => s.collectionHintShown = true);
      _toast(S.tapForCollection);
    }
  }

  /// Le feste aspettano che il taglio sia finito e che non sia aperto
  /// nient'altro (pannello del layout, posizionamento, salvataggio).
  Future<void> _maybeCelebrate() async {
    if (_celebrating || !mounted) return;
    if (c.animation != null ||
        c.layoutPanelOpen ||
        c.positioning ||
        c.busyExporting) {
      return;
    }
    if (_pendingEvolutions.isEmpty && _pendingMilestones.isEmpty) return;
    _celebrating = true;
    try {
      while (_pendingMilestones.isNotEmpty && _pendingEvolutions.isEmpty) {
        _pendingMilestones.removeAt(0);
        _toast(S.bucketFilled);
      }
      _pendingMilestones.clear();
      while (_pendingEvolutions.isNotEmpty && mounted) {
        final skin = _pendingEvolutions.removeAt(0);
        if (!mounted) return;
        await showEvolution(context, skin);
        if (!mounted) return;
        if (!_rubble.firstEvolutionDone) {
          // la prima volta si apre da sola, per far scoprire la Collezione
          _rubble.flag((s) => s.firstEvolutionDone = true);
          await CollectionScreen.open(
            context,
            _rubble,
            highlight: skin,
            afterEvolution: true,
          );
        } else {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(S.newSkinToast),
                action: SnackBarAction(
                  label: S.see,
                  onPressed: () =>
                      CollectionScreen.open(context, _rubble, highlight: skin),
                ),
              ),
            );
        }
      }
    } finally {
      _celebrating = false;
    }
  }

  void _setSmash(bool on) {
    c.setSmash(on);
    if (!on && !_rubble.sleepToastShown) {
      _rubble.flag((s) => s.sleepToastShown = true);
      _toast(S.smashSleeps);
    }
  }

  void _openCollectionOrWake() {
    if (!c.smashEnabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(S.activateSmash),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'ON',
              onPressed: () => _setSmash(true),
            ),
          ),
        );
      return;
    }
    if (c.isCutting) return;
    CollectionScreen.open(context, _rubble);
  }

  /// Un ticker per animazione: se parte un nuovo taglio il tempo riparte da 0.
  void _syncTicker() {
    final a = c.animation;
    if (a != null && !identical(a, _runningFor)) {
      _runningFor = a;
      if (_ticker.isActive) _ticker.stop();
      _ticker.start();
    } else if (a == null && _ticker.isActive) {
      _runningFor = null;
      _ticker.stop();
    }
    if (a == null) _maybeCelebrate();
  }

  @override
  void dispose() {
    _rubble.removeListener(_onRubble);
    c.removeListener(_syncTicker);
    _ticker.dispose();
    c.dispose();
    super.dispose();
  }

  /// Un file salvato o condiviso: evento per le campagne e, la prima volta,
  /// l'invito a "SmashCrop a vita" (una volta sola, solo nelle app).
  void _savedOk() {
    AdsTracker.instance.firstSave();
    final s = RubbleStore.instance;
    if (kIsWeb) return;
    final offer = !s.lifetime && !s.lifetimeOffered;
    final ask = !s.notifyAsked;
    if (!offer && !ask) return;
    if (offer) s.flag((s) => s.lifetimeOffered = true);
    Future<void>.delayed(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      // prima l'invito a "SmashCrop a vita", poi il permesso per le notifiche
      if (offer) {
        await showLifetimeSheet(context, intro: S.lifetimeOfferIntro);
      }
      if (ask) await Notifications.instance.askPermission();
    });
  }

  // --- OctoSmash ---------------------------------------------------------------

  /// Ultimo colore usato (per la testa e il contatore dell'inchiostro).
  bool _octoWhite = false;

  String _octoHead({bool sleep = false}) =>
      'assets/octo/testa${sleep ? '_dorme' : ''}_${_octoWhite ? 'nero' : 'bianco'}.webp';

  bool _octoSleepToast = false;

  void _setOcto(bool on) {
    c.setOcto(on);
    if (!on && !_octoSleepToast) {
      _octoSleepToast = true;
      _toast(S.octoSleeps);
    }
  }

  void _enterOcto() {
    if (!c.canEnterOcto) return;
    HapticFeedback.heavyImpact();
    c.enterOcto();
  }

  void _addOcto(bool white) {
    HapticFeedback.selectionClick();
    c.cancelPicking();
    setState(() => _octoWhite = white);
    c.addOctoRect(color: white ? InkFill.whiteInk : InkFill.black);
  }

  void _pick() {
    HapticFeedback.selectionClick();
    if (c.octoPicking) {
      c.cancelPicking();
    } else {
      c.startPicking();
    }
  }

  Future<void> _palette() async {
    c.cancelPicking();
    final color = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (ctx) => OctoPalette(recent: List.of(c.pickedColors)),
    );
    if (color != null) {
      HapticFeedback.selectionClick();
      c.addOctoRect(color: color);
    }
  }

  /// [⬜+] [⬛+] [✓ Fatto] [💧] [🎨] — tocco lungo su Fatto: esci.
  Widget _octoRow() {
    Widget box({
      required String label,
      required Color fill,
      required Color border,
      required Widget child,
      required VoidCallback? onTap,
      Gradient? gradient,
    }) => SizedBox(
      width: 48,
      height: 48,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gradient == null ? fill : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1.4),
            ),
            child: child,
          ),
        ),
      ),
    );
    final picked = c.pickedColors.isEmpty ? null : Color(c.pickedColors.first);
    // mentre si sceglie, il tasto è del colore sotto il mirino
    final live = c.octoPicking && c.livePickColor != null
        ? Color(c.livePickColor!)
        : null;
    final liveDark = live != null && live.computeLuminance() < .45;
    return Row(
      children: [
        box(
          label: 'Bianco',
          fill: Colors.white,
          border: const Color(0xFFB8BEC8),
          onTap: () => _addOcto(true),
          child: const Icon(Icons.add, size: 28, color: Colors.black),
        ),
        const SizedBox(width: 6),
        box(
          label: 'Nero',
          fill: Colors.black,
          border: const Color(0xFF8A919C),
          onTap: () => _addOcto(false),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              c.exitOcto();
            },
            child: AppButton(
              label: S.fineDone,
              icon: const Icon(Icons.check),
              style: AppButtonStyle.primary,
              height: 48,
              fontSize: 16,
              hideIconBelow: 120,
              onPressed:
                  c.octoRects.isEmpty || c.octoSplash != null || c.octoAnimating
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      c.commitOcto();
                    },
            ),
          ),
        ),
        const SizedBox(width: 6),
        box(
          label: 'Pipetta',
          fill:
              live ??
              (c.octoPicking ? const Color(0xFF22E4F2) : AppColors.button),
          border: c.octoPicking ? Colors.white : AppColors.border,
          onTap: _pick,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.colorize,
                size: 24,
                color: liveDark
                    ? Colors.white
                    : (c.octoPicking ? Colors.black : AppColors.text),
              ),
              if (picked != null && !c.octoPicking)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: picked,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        box(
          label: 'Tavolozza',
          fill: AppColors.button,
          border: AppColors.border,
          onTap: _palette,
          child: const Icon(Icons.palette, size: 24, color: Colors.white),
          gradient: const SweepGradient(
            colors: [
              Color(0xFFE5484D),
              Color(0xFFF5A524),
              Color(0xFFF7E15A),
              Color(0xFF3DD68C),
              Color(0xFF22B8F2),
              Color(0xFF7C5CFF),
              Color(0xFFE54DB5),
              Color(0xFFE5484D),
            ],
          ),
        ),
      ],
    );
  }

  /// [ ◀ ]  ⟳ 3°  [ ▶ ]: 1 grado alla volta; toccando il numero torna a 0°.
  Widget _angleControl() {
    final r = c.octoCurrent;
    final on = r != null;
    Widget step(IconData icon, double deg) => _NudgeButton(
      label: '',
      icon: icon,
      color: kHorizontalColor,
      onStep: () {
        if (c.octoCurrent == null) return;
        c.rotateSelectedOcto(deg);
        HapticFeedback.selectionClick();
      },
      onEnd: () {},
    );
    return Opacity(
      opacity: on ? 1 : .4,
      child: IgnorePointer(
        ignoring: !on,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 36, child: step(Icons.rotate_left, -1)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: c.straightenSelectedOcto,
              child: Container(
                width: 52,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.button,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${r?.degrees ?? 0}°',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(height: 36, child: step(Icons.rotate_right, 1)),
          ],
        ),
      ),
    );
  }

  // --- precisione al pixel ---------------------------------------------------

  bool _fine = false;

  void _tapOrientation(CutOrientation o) {
    c.tapOrientation(o);
    final prefs = c.preferences;
    if (prefs.fineHintShown) return;
    prefs.setFineHintShown();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.fineTitle),
        content: Text(S.fineHint, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openFine() {
    HapticFeedback.mediumImpact();
    setState(() => _fine = true);
  }

  void _closeFine() {
    c.endNudge();
    setState(() => _fine = false);
  }

  /// Riga di regolazione fine: [A ▲][A ▼]  ✓ Fatto  [B ▲][B ▼]
  /// (in verticale ◀ ▶). Ogni tocco sposta di 1 pixel; tenendo premuto scorre.
  Widget _fineRow(CutOrientation mode) {
    final h = mode == CutOrientation.horizontal;
    final color = h ? kHorizontalColor : kVerticalColor;
    Widget arrow(LineHandle line, int step) => _NudgeButton(
      label: line == LineHandle.a ? 'A' : 'B',
      icon: h
          ? (step < 0 ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down)
          : (step < 0 ? Icons.keyboard_arrow_left : Icons.keyboard_arrow_right),
      color: color,
      onStep: () {
        if (c.nudgeLine(line, step)) HapticFeedback.selectionClick();
      },
      onEnd: c.endNudge,
    );
    return Row(
      children: [
        arrow(LineHandle.a, -1),
        const SizedBox(width: 4),
        arrow(LineHandle.a, 1),
        const SizedBox(width: 6),
        Expanded(
          child: AppButton(
            label: S.fineDone,
            icon: const Icon(Icons.check),
            height: 48,
            fontSize: 16,
            hideIconBelow: 110,
            onPressed: _closeFine,
          ),
        ),
        const SizedBox(width: 6),
        arrow(LineHandle.b, -1),
        const SizedBox(width: 4),
        arrow(LineHandle.b, 1),
      ],
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _withLoading(String label, Future<void> Function() job) async {
    if (_loadingLabel != null || c.isCutting) return;
    setState(() => _loadingLabel = label);
    try {
      await job();
    } finally {
      if (mounted) setState(() => _loadingLabel = null);
    }
  }

  Future<void> _loadImage() => _withLoading(S.opening, () async {
    try {
      final picked = await _imageLoader.pickMany(
        confirmSize: (bytes) => confirmLargeImages(context, bytes),
        onTruncated: (max) => _toast(S.onlyFirstImages(max)),
      );
      if (picked != null) c.replaceWithImages(picked);
    } on ImageLoadException catch (e) {
      _toast(e.tooLarge ? S.tooLarge : S.loadFailed);
    } catch (_) {
      _toast(S.loadFailed);
    }
  });

  Future<void> _addImages() async {
    if (!c.canAddImages) {
      if (c.imagesRoom <= 0) _toast(S.imagesLimit(ImageLoader.maxImages));
      return;
    }
    await _withLoading(S.opening, () async {
      try {
        final picked = await _imageLoader.pickMany(
          max: c.imagesRoom,
          confirmSize: (bytes) => confirmLargeImages(context, bytes),
          onTruncated: (max) => _toast(S.imagesLimit(max)),
        );
        if (picked != null) c.addImages(picked);
      } on ImageLoadException catch (e) {
        _toast(e.tooLarge ? S.tooLarge : S.loadFailed);
      } catch (_) {
        _toast(S.loadFailed);
      }
    });
  }

  /// "Rimuovi porzione": se A e B prendono tutta la pagina si propone di
  /// togliere la pagina (se è l'unica, si spiega perché non si può).
  void _onRemovePressed() {
    if (c.canCut) {
      if (c.removePortion()) AdsTracker.instance.firstCut();
      return;
    }
    if (!c.selectsWholePage) return;
    if (c.canRemovePage) {
      _removePage(wholePage: true);
    } else {
      _toast(S.cannotRemoveAll);
    }
  }

  Future<void> _removePage({bool wholePage = false}) async {
    if (!c.canRemovePage) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(wholePage ? S.wholePageTitle : S.removePageTitle),
        content: Text(
          c.isPdf ? S.removePdfPageBody : S.removePageBody,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.remove),
          ),
        ],
      ),
    );
    if (ok == true) c.removeCurrentPage();
  }

  Future<void> _loadPdf() => _withLoading(S.pdfOpening, () async {
    try {
      final pdf = await _pdfLoader.pick(
        askPassword: ({required bool wrong}) =>
            askPdfPassword(context, wrong: wrong),
        confirmSize: (bytes) => confirmLargePdf(context, bytes),
      );
      if (pdf != null) c.replaceWithPdf(pdf);
    } on PdfOpenException catch (e) {
      if (!e.cancelled) {
        _toast(
          e.locked
              ? S.pdfLocked
              : (e.password
                    ? S.pdfPassword
                    : S.withDetail(S.pdfInvalid, e.detail)),
        );
      }
    } catch (e) {
      _toast(S.withDetail(S.pdfInvalid, '$e'));
    }
  });

  Rect? _shareOrigin() {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  /// Per le immagini si chiede ogni volta come salvare: con una sola parte
  /// già scelto "Immagine", con più di una "PDF". `null` = annullato.
  Future<_Output?> _askOutput({bool share = false}) async {
    if (c.isPdf) return _Output.pdf;
    final many = c.images.length;
    final def = many > 1 ? _Output.pdf : _Output.images;
    Widget option(_Output o) {
      final label = o == _Output.pdf
          ? (many > 1 ? S.saveAsPdfPages(many) : S.saveAsPdf)
          : (many > 1
                ? S.saveAsImages(many)
                : S.saveAsImage(c.images.first.format.extension.toUpperCase()));
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AppButton(
          label: label,
          icon: Icon(
            o == _Output.pdf
                ? Icons.picture_as_pdf_outlined
                : (many > 1
                      ? Icons.collections_outlined
                      : Icons.image_outlined),
          ),
          style: o == def ? AppButtonStyle.primary : AppButtonStyle.secondary,
          height: 50,
          fontSize: 16,
          onPressed: () => Navigator.pop(context, o),
        ),
      );
    }

    return showDialog<_Output>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(share ? S.shareAsTitle : S.saveAsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            option(def),
            option(def == _Output.pdf ? _Output.images : _Output.pdf),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.cancel),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _pdfBytes() =>
      c.isPdf ? c.buildPdfExport() : c.buildImagesPdfExport();

  Future<void> _save() async {
    if (c.isCutting) return;
    final out = await _askOutput();
    if (out == null) return;
    try {
      if (out == _Output.pdf) {
        final bytes = await _pdfBytes();
        if (bytes == null) return;
        final name = '${ExportService.baseFileName()}.pdf';
        if (kIsWeb) {
          await _webSave(bytes, name, 'application/pdf', image: false);
          return;
        }
        final uri = await FilePicker.saveFile(
          fileName: name,
          bytes: bytes,
          mimeType: 'application/pdf',
        );
        // su web il file viene scaricato senza conferma
        if (uri != null || kIsWeb) {
          _savedOk();
          _toast(kIsWeb ? S.downloaded : S.pdfSaved);
        }
        return;
      }
      final files = await c.buildImageExports();
      if (files == null || files.isEmpty) return;
      if (kIsWeb) {
        if (files.length == 1) {
          final f = files.first;
          await _webSave(f.bytes, f.fileName, f.mimeType, image: true);
        } else {
          await _webSaveMany(files);
        }
        return;
      }
      final (n, outcome) = await c.exporter.saveAllToPhotos(files);
      if (outcome == SaveOutcome.saved) _savedOk();
      _toast(switch (outcome) {
        SaveOutcome.saved => files.length > 1 ? S.savedMany(n) : S.saved,
        SaveOutcome.denied => S.saveDenied,
        SaveOutcome.unavailable => S.saveUnavailable,
        SaveOutcome.failed => S.saveFailed,
      });
    } catch (_) {
      _toast(S.saveFailed);
    }
  }

  /// Più immagini nel browser: se il telefono le accetta tutte insieme, un
  /// tocco apre il menu di condivisione ("Salva N immagini"); altrimenti si
  /// scaricano una dopo l'altra.
  Future<void> _webSaveMany(List<ExportedFile> files) async {
    Future<void> downloadAll() async {
      var ok = true;
      for (final f in files) {
        ok = await c.exporter.download(f.bytes, f.fileName, f.mimeType) && ok;
      }
      if (ok) _savedOk();
      _toast(ok ? S.downloaded : S.saveFailed);
    }

    final list = [for (final f in files) (f.bytes, f.fileName, f.mimeType)];
    if (!web_share.canShareFiles(list)) {
      await downloadAll();
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.fileReady),
        content: Text(
          S.saveToGalleryHint,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              downloadAll();
            },
            child: Text(S.download),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              Navigator.pop(context);
              web_share.shareFiles(list);
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(S.saveToGallery),
          ),
        ],
      ),
    );
  }

  /// Nel browser del telefono si passa dal menu di condivisione: da lì
  /// "Salva immagine" mette l'immagine in Galleria/Foto e "Salva su File"
  /// salva il PDF. Il menu va aperto con un tocco, per questo c'è il
  /// pulsante nella finestra. Sul computer il file si scarica.
  Future<void> _webSave(
    Uint8List bytes,
    String name,
    String mime, {
    required bool image,
  }) async {
    if (!web_share.canShareFile(bytes, name, mime)) {
      final ok = await c.exporter.download(bytes, name, mime);
      _toast(ok ? S.downloaded : S.saveFailed);
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.fileReady),
        content: Text(
          image ? S.saveToGalleryHint : S.saveToFilesHint,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await c.exporter.download(bytes, name, mime);
              _toast(ok ? S.downloaded : S.saveFailed);
            },
            child: Text(S.download),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () {
              Navigator.pop(context);
              web_share.shareFile(bytes, name, mime);
            },
            icon: Icon(
              image ? Icons.photo_library_outlined : Icons.folder_outlined,
            ),
            label: Text(image ? S.saveToGallery : S.saveToFiles),
          ),
        ],
      ),
    );
  }

  Future<void> _share() async {
    if (c.isCutting) return;
    final out = await _askOutput(share: true);
    if (out == null) return;
    try {
      bool ok;
      if (out == _Output.pdf) {
        final bytes = await _pdfBytes();
        if (bytes == null) return;
        ok = await c.exporter.shareBytes(
          bytes,
          'application/pdf',
          '${ExportService.baseFileName()}.pdf',
          origin: _shareOrigin(),
        );
      } else {
        final files = await c.buildImageExports();
        if (files == null || files.isEmpty) return;
        ok = files.length == 1
            ? await c.exporter.share(files.first, origin: _shareOrigin())
            : await c.exporter.shareAll(files, origin: _shareOrigin());
      }
      ok ? _savedOk() : _toast(S.shareFailed);
    } catch (_) {
      _toast(S.shareFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: AnimatedBuilder(
                animation: c,
                builder: (context, _) => _layout(),
              ),
            ),
            Positioned.fill(
              child: RubbleOverlay(
                controller: c,
                images: _skinImgs,
                viewportKey: _viewportKey,
                targetKey: _headKey,
                bottomKey: _bottomKey,
                onImpact: _onImpact,
                onArrive: _onArrive,
              ),
            ),
            AnimatedBuilder(
              animation: c,
              builder: (context, _) {
                final label = c.busyExporting ? S.preparing : _loadingLabel;
                if (label == null) return const SizedBox.shrink();
                return Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x99000000),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.red),
                          const SizedBox(height: 14),
                          Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _layout() {
    final locked = c.isCutting || c.positioning || c.layoutPanelOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            MenuButton(
              onTap: locked
                  ? null
                  : () => showAppMenu(
                      context,
                      preferences: widget.preferences,
                      sections: rubbleMenuSections(
                        context,
                        _rubble,
                        modeSwitch: c.octoMode || c.canEnterOcto
                            ? MenuEntry(
                                icon: Icons.swap_horiz,
                                label: c.octoMode
                                    ? S.switchToSmash
                                    : S.switchToOcto,
                                onTap: () {
                                  Navigator.pop(context);
                                  c.octoMode ? c.exitOcto() : _enterOcto();
                                },
                              )
                            : null,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: c.octoMode
                  ? Opacity(
                      opacity: c.octoEnabled ? 1 : .55,
                      child: InkCounterBar(
                        store: _rubble,
                        white: _octoWhite,
                        awake: c.octoEnabled,
                      ),
                    )
                  : CounterBar(
                      store: _rubble,
                      awake: c.smashEnabled,
                      headKey: _headKey,
                      onTap: _openCollectionOrWake,
                    ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              key: _shareKey,
              width: 44,
              child: AppButton(
                label: '',
                semanticLabel: S.share,
                icon: const Icon(Icons.ios_share),
                height: 40,
                onPressed: locked ? null : _share,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 96,
              child: AppButton(
                label: S.save,
                icon: const Icon(Icons.save_outlined),
                style: AppButtonStyle.primary,
                height: 40,
                fontSize: 14,
                onPressed: locked ? null : _save,
              ),
            ),
          ],
        ),
        // zoom: barra sottile e centrata, senza scritte
        Center(
          child: FractionallySizedBox(
            widthFactor: .62,
            child: SizedBox(
              height: 26,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: AppColors.red,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.red,
                  disabledThumbColor: AppColors.textMuted,
                  overlayShape: SliderComponentShape.noOverlay,
                  thumbShape: const _FlatThumb(),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: c.zoom,
                  min: ViewportTransform.minZoom,
                  max: ViewportTransform.maxZoom,
                  semanticFormatterCallback: (v) =>
                      '${S.zoom} ${v.toStringAsFixed(1)}x',
                  onChanged: locked || !c.pageReady ? null : c.setZoom,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: KeyedSubtree(
            key: _viewportKey,
            child: ValueListenableBuilder<int>(
              valueListenable: c.frameTick,
              child: EditorViewport(controller: c, frames: _frames),
              builder: (context, _, child) {
                final a = c.animation;
                final skin = _skinImgs?.skin.id;
                if (a == null ||
                    skin == null ||
                    a.rubbleKg <= 0 ||
                    (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
                  return child!;
                }
                final sec = (a.elapsedMs - a.timeline.impactMs) / 1000;
                return Transform.translate(
                  offset: SkinEffects.shake(
                    skin,
                    sec,
                    SkinEffects.powerFor(a.rubbleKg),
                  ),
                  child: child,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Column(
          key: _bottomKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _bottom(),
        ),
      ],
    );
  }

  List<Widget> _bottom() {
    if (c.positioning) return [_positioningBar()];
    if (c.layoutPanelOpen) {
      return [
        LayoutPanel(
          selected: c.previewLayout?.mode ?? c.layoutSuggestion,
          onSelect: c.previewLayoutMode,
          onApply: c.applyLayout,
          onClose: c.dismissLayoutPanel,
          forNext: c.layoutForNext,
          onForNextChanged: c.pageCount > 1 ? c.setLayoutForNext : null,
        ),
      ];
    }
    final mode = c.selection.mode;
    final selVisible = c.selectionVisible;
    // senza selezione o durante il taglio la regolazione fine si chiude
    if (_fine && (mode == null || !selVisible || c.isCutting)) _fine = false;
    return [
      if (c.hasPages || !c.isPdf) ...[_pdfBar(), const SizedBox(height: 8)],
      // undo · orizzontale · RIMUOVI PORZIONE · verticale · redo
      // (tenendo premuto l'orientamento attivo: frecce di precisione)
      if (c.octoMode)
        _octoRow()
      else if (_fine && mode != null && selVisible && !c.isCutting)
        _fineRow(mode)
      else
        Row(
          children: [
            _square(
              icon: const Icon(Icons.undo),
              label: S.undo,
              onPressed: c.canUndo ? c.undo : null,
            ),
            const SizedBox(width: 6),
            _OrientationSquare(
              label: S.horizontal,
              vertical: false,
              color: kHorizontalColor,
              active: mode == CutOrientation.horizontal && selVisible,
              onPressed: c.isCutting || !c.pageReady
                  ? null
                  : () => _tapOrientation(CutOrientation.horizontal),
              onLongPress:
                  mode == CutOrientation.horizontal &&
                      selVisible &&
                      !c.isCutting
                  ? _openFine
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              // tocco lungo (0,8 s): si entra in OctoSmash
              child: RawGestureDetector(
                gestures: {
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(
                        () => LongPressGestureRecognizer(
                          duration: const Duration(milliseconds: 800),
                        ),
                        (g) => g.onLongPress = _enterOcto,
                      ),
                },
                child: AppButton(
                  label: S.removePortion,
                  icon: const Icon(Icons.content_cut),
                  style: AppButtonStyle.primary,
                  height: 48,
                  fontSize: 16,
                  hideIconBelow: 170,
                  onPressed: c.canPressCut ? _onRemovePressed : null,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _OrientationSquare(
              label: S.vertical,
              vertical: true,
              color: kVerticalColor,
              active: mode == CutOrientation.vertical && selVisible,
              onPressed: c.isCutting || !c.pageReady
                  ? null
                  : () => _tapOrientation(CutOrientation.vertical),
              onLongPress:
                  mode == CutOrientation.vertical && selVisible && !c.isCutting
                  ? _openFine
                  : null,
            ),
            const SizedBox(width: 6),
            _square(
              icon: const Icon(Icons.redo),
              label: S.redo,
              onPressed: c.canRedo ? c.redo : null,
            ),
          ],
        ),
      const SizedBox(height: 8),
      // carica immagini · SMASH · carica PDF
      Row(
        children: [
          Expanded(
            child: ImagePickTarget(
              onTap: c.isCutting ? null : _loadImage,
              child: AppButton(
                label: S.loadImage,
                icon: const Icon(Icons.image_outlined),
                height: 42,
                fontSize: 14,
                hideIconBelow: 132,
                onPressed: c.isCutting ? null : _loadImage,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 104,
            child: c.octoMode
                // in OctoSmash spegnere addormenta OctoSmash (niente
                // animazione), come per SMASH
                ? SmashToggle(
                    value: c.octoEnabled,
                    onChanged: _setOcto,
                    awakeAsset: _octoHead(),
                    sleepAsset: _octoHead(sleep: true),
                    height: 42,
                  )
                : SmashToggle(
                    value: c.smashEnabled,
                    onChanged: _setSmash,
                    awakeAsset: _rubble.skin.head,
                    sleepAsset: _rubble.skin.headSleep,
                    height: 42,
                  ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AppButton(
              label: S.loadPdf,
              icon: const Icon(Icons.description_outlined),
              height: 42,
              fontSize: 14,
              hideIconBelow: 112,
              onPressed: c.isCutting ? null : _loadPdf,
            ),
          ),
        ],
      ),
    ];
  }

  /// Pulsante quadrato con sola icona (Annulla, Ripeti).
  Widget _square({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: _kSquare,
    child: AppButton(
      label: '',
      semanticLabel: label,
      icon: icon,
      height: _kSquare,
      onPressed: onPressed,
    ),
  );

  /// Navigatore compatto delle pagine e pulsante Layout PDF, in una riga.
  /// "Pag. 2 di 5 ▾": toccandola si apre il menu della pagina corrente
  /// (spostarla prima o dopo, toglierla).
  Widget _pageMenu() {
    final enabled = c.canNavigate && c.pageCount > 1;
    PopupMenuItem<int> item(int v, IconData icon, String label, bool on) =>
        PopupMenuItem<int>(
          value: v,
          enabled: on,
          height: 46,
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: on ? AppColors.text : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: on ? AppColors.text : AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
    final label = Container(
      height: 36,
      padding: const EdgeInsets.only(left: 12, right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.button,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.pageOf(c.pageIndex + 1, c.pageCount),
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (c.pageCount > 1) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.expand_more,
                size: 18,
                color: enabled ? AppColors.text : AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
    if (c.pageCount < 2) return label;
    return PopupMenuButton<int>(
      enabled: enabled,
      tooltip: S.pageOptions,
      position: PopupMenuPosition.over,
      color: AppColors.surface,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: (v) {
        switch (v) {
          case -1:
          case 1:
            c.movePage(v);
          case 0:
            _removePage();
        }
      },
      itemBuilder: (context) => [
        item(-1, Icons.arrow_back, S.movePageBack, c.canMovePage(-1)),
        item(1, Icons.arrow_forward, S.movePageForward, c.canMovePage(1)),
        item(0, Icons.delete_outline, S.removePage, c.canRemovePage),
      ],
      child: label,
    );
  }

  Widget _pdfBar() {
    final nav = c.canNavigate;
    Widget arrow(IconData icon, VoidCallback? onTap, String label) => SizedBox(
      width: 40,
      child: AppButton(
        label: '',
        semanticLabel: label,
        icon: Icon(icon),
        height: 36,
        onPressed: onTap,
      ),
    );
    return Row(
      children: [
        arrow(
          Icons.chevron_left,
          nav && c.pageIndex > 0 ? () => c.goToPage(c.pageIndex - 1) : null,
          S.previousPage,
        ),
        const SizedBox(width: 6),
        Flexible(
          flex: 20,
          child: c.octoMode
              ? AppButton(
                  label: 'SMASH',
                  icon: const Icon(Icons.arrow_back),
                  height: 36,
                  fontSize: 14,
                  onPressed: c.exitOcto,
                )
              : _pageMenu(),
        ),
        const SizedBox(width: 6),
        arrow(
          Icons.chevron_right,
          nav && c.pageIndex < c.pageCount - 1
              ? () => c.goToPage(c.pageIndex + 1)
              : null,
          S.nextPage,
        ),
        const Spacer(),
        if (c.octoMode) _angleControl(),
        if (!c.octoMode && !c.isPdf) ...[
          SizedBox(
            width: 112,
            child: ImagePickTarget(
              onTap: c.canAddImages ? _addImages : null,
              child: AppButton(
                label: S.addImages,
                semanticLabel: S.addImagesLabel,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                height: 36,
                fontSize: 14,
                hideIconBelow: 104,
                onPressed: c.canAddImages ? _addImages : null,
              ),
            ),
          ),
        ],
        if (!c.octoMode && c.isPdf)
          SizedBox(
            width: 124,
            child: AppButton(
              label: S.layoutPdf,
              icon: const Icon(Icons.dashboard_customize_outlined),
              height: 36,
              fontSize: 14,
              onPressed: nav && c.pageReady && c.page.history.hasCuts
                  ? c.openLayoutPanel
                  : null,
            ),
          ),
        const SizedBox(width: 6),
        // con rettangoli in lavorazione il cestino toglie il rettangolo,
        // mai la pagina
        if (c.octoMode && c.octoRects.isNotEmpty)
          arrow(
            Icons.delete_outline,
            c.octoSelected != null ? c.deleteSelectedOcto : null,
            S.removePage,
          )
        else
          arrow(
            Icons.delete_outline,
            c.canRemovePage ? _removePage : null,
            S.removePage,
          ),
      ],
    );
  }

  Widget _positioningBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.open_with, color: AppColors.text, size: 22),
              SizedBox(width: 8),
              Text(
                S.positionTitle,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            S.positionHint,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppButton(
                  label: S.cancel,
                  height: 50,
                  fontSize: 16,
                  onPressed: c.cancelPositioning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: AppButton(
                  label: S.confirmPosition,
                  icon: const Icon(Icons.check),
                  style: AppButtonStyle.primary,
                  height: 50,
                  fontSize: 16,
                  onPressed: c.confirmPosition,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _Output { images, pdf }

const double _kSquare = 48;

/// Colori dei due orientamenti quando sono attivi.
const Color kHorizontalColor = Color(0xFF1E7BFF); // blu elettrico
const Color kVerticalColor = Color(0xFFFF2BD1); // fucsia da città futuristica

/// Quadrato dell'orientamento: grigio a riposo, acceso nel suo colore.
class _OrientationSquare extends StatelessWidget {
  const _OrientationSquare({
    required this.label,
    required this.vertical,
    required this.color,
    required this.active,
    required this.onPressed,
    this.onLongPress,
  });
  final String label;
  final bool vertical;
  final Color color;
  final bool active;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      selected: active,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: active ? color : AppColors.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: active ? color : AppColors.border,
            width: active ? 1.6 : 1,
          ),
        ),
        shadowColor: color,
        elevation: active ? 6 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          onLongPress: onLongPress,
          child: SizedBox.square(
            dimension: _kSquare,
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  color: !enabled
                      ? AppColors.textMuted
                      : (active ? Colors.white : AppColors.text),
                  size: 24,
                ),
                child: DoubleArrow(vertical: vertical, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cursore dello zoom piatto e rettangolare, al posto del pallino.
class _FlatThumb extends SliderComponentShape {
  const _FlatThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 10);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final color = enableAnimation.value > .5
        ? (sliderTheme.thumbColor ?? AppColors.red)
        : (sliderTheme.disabledThumbColor ?? AppColors.textMuted);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 20, height: 10),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );
  }
}

/// Freccia della regolazione fine: un tocco = 1 pixel; tenendo premuto
/// scorre, prima piano e poi più veloce.
class _NudgeButton extends StatefulWidget {
  const _NudgeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onStep,
    required this.onEnd,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onStep;
  final VoidCallback onEnd;

  @override
  State<_NudgeButton> createState() => _NudgeButtonState();
}

class _NudgeButtonState extends State<_NudgeButton> {
  Timer? _timer;
  int _ticks = 0;
  bool _down = false;

  void _start() {
    setState(() => _down = true);
    _ticks = 0;
    widget.onStep();
    _timer = Timer(const Duration(milliseconds: 420), _repeat);
  }

  void _repeat() {
    if (!_down) return;
    widget.onStep();
    _ticks++;
    final ms = _ticks < 12 ? 90 : 35;
    _timer = Timer(Duration(milliseconds: ms), _repeat);
  }

  void _stop() {
    _timer?.cancel();
    if (!_down) return;
    setState(() => _down = false);
    widget.onEnd();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: Container(
          width: 44,
          height: _kSquare,
          decoration: BoxDecoration(
            color: _down ? widget.color : AppColors.button,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  height: 1,
                  color: _down ? Colors.white : widget.color,
                ),
              ),
              Icon(
                widget.icon,
                size: 24,
                color: _down ? Colors.white : AppColors.text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
