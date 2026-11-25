import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/large_file_dialog.dart';
import '../../../core/widgets/password_dialog.dart';

import '../../../app/strings.dart';
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
import '../../pdf_processing/presentation/layout_panel.dart';
import '../../pdf_processing/services/pdf_loader.dart';
import '../../pdf_processing/services/pdf_service.dart';
import '../../settings/preferences.dart';
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

  Future<void> _removePage() async {
    if (!c.canRemovePage) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.removePageTitle),
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
  Future<_Output?> _askOutput() async {
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
        title: Text(S.saveAsTitle),
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
        if (uri != null || kIsWeb) _toast(kIsWeb ? S.downloaded : S.pdfSaved);
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
    final out = await _askOutput();
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
      if (!ok) _toast(S.shareFailed);
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
                      sections: rubbleMenuSections(context, _rubble),
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CounterBar(
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
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: AppButton(
                label: S.undo,
                icon: const Icon(Icons.undo),
                height: 38,
                fontSize: 14,
                onPressed: c.canUndo ? c.undo : null,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: AppButton(
                label: S.redo,
                icon: const Icon(Icons.redo),
                height: 38,
                fontSize: 14,
                onPressed: c.canRedo ? c.redo : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 38,
              width: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.button,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${c.zoom.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: c.zoom,
                min: ViewportTransform.minZoom,
                max: ViewportTransform.maxZoom,
                onChanged: locked || !c.pageReady ? null : c.setZoom,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
    return [
      if (c.hasPages || !c.isPdf) ...[_pdfBar(), const SizedBox(height: 8)],
      AppButton(
        label: S.removePortion,
        icon: const Icon(Icons.content_cut),
        style: AppButtonStyle.primary,
        height: 54,
        fontSize: 18,
        onPressed: c.canCut ? c.removePortion : null,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: AppButton(
              label: S.horizontal,
              icon: const DoubleArrow(vertical: false),
              style: mode == CutOrientation.horizontal && selVisible
                  ? AppButtonStyle.selected
                  : AppButtonStyle.secondary,
              fontSize: 14,
              hideIconBelow: 124,
              onPressed: c.isCutting || !c.pageReady
                  ? null
                  : () => c.tapOrientation(CutOrientation.horizontal),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              label: S.vertical,
              icon: const DoubleArrow(vertical: true),
              style: mode == CutOrientation.vertical && selVisible
                  ? AppButtonStyle.selected
                  : AppButtonStyle.secondary,
              fontSize: 14,
              hideIconBelow: 124,
              onPressed: c.isCutting || !c.pageReady
                  ? null
                  : () => c.tapOrientation(CutOrientation.vertical),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SmashToggle(
              value: c.smashEnabled,
              onChanged: _setSmash,
              awakeAsset: _rubble.skin.head,
              sleepAsset: _rubble.skin.headSleep,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: AppButton(
              label: S.loadImage,
              icon: const Icon(Icons.image_outlined),
              fontSize: 15,
              onPressed: c.isCutting ? null : _loadImage,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppButton(
              label: S.loadPdf,
              icon: const Icon(Icons.description_outlined),
              fontSize: 15,
              onPressed: c.isCutting ? null : _loadPdf,
            ),
          ),
        ],
      ),
    ];
  }

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
        Flexible(flex: 20, child: _pageMenu()),
        const SizedBox(width: 6),
        arrow(
          Icons.chevron_right,
          nav && c.pageIndex < c.pageCount - 1
              ? () => c.goToPage(c.pageIndex + 1)
              : null,
          S.nextPage,
        ),
        const Spacer(),
        if (!c.isPdf) ...[
          SizedBox(
            width: 112,
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
        ],
        if (c.isPdf)
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
