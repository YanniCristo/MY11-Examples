import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/password_dialog.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand.dart';
import '../../animation/application/smash_frames.dart';
import '../../export/export_service.dart';
import '../../image_processing/services/image_loader.dart';
import '../../pdf_processing/domain/page_layout.dart';
import '../../pdf_processing/presentation/layout_panel.dart';
import '../../pdf_processing/services/pdf_loader.dart';
import '../../pdf_processing/services/pdf_service.dart';
import '../../settings/preferences.dart';
import '../application/editor_controller.dart';
import '../domain/cut_operation.dart';
import '../domain/viewport_transform.dart';
import 'editor_viewport.dart';
import 'smash_toggle.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.preferences,
    this.image,
    this.pdf,
  }) : assert((image == null) != (pdf == null));

  final AppPreferences preferences;
  final LoadedImage? image;
  final PdfSession? pdf;

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

  @override
  void initState() {
    super.initState();
    c = widget.image != null
        ? EditorController.image(
            image: widget.image!,
            preferences: widget.preferences,
          )
        : EditorController.pdf(
            session: widget.pdf!,
            preferences: widget.preferences,
          );
    _ticker = createTicker(c.tick);
    c.addListener(_syncTicker);
    SmashFrames.load()
        .then((f) {
          if (!mounted) return;
          setState(() => _frames = f.frames);
          c.smashAvailable = true;
        })
        .catchError((_) {});
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
  }

  @override
  void dispose() {
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
      final img = await _imageLoader.pick();
      if (img != null) c.replaceWithImage(img);
    } on ImageLoadException catch (e) {
      _toast(e.tooLarge ? S.tooLarge : S.loadFailed);
    } catch (_) {
      _toast(S.loadFailed);
    }
  });

  Future<void> _loadPdf() => _withLoading(S.pdfOpening, () async {
    try {
      final pdf = await _pdfLoader.pick(
        askPassword: ({required bool wrong}) =>
            askPdfPassword(context, wrong: wrong),
      );
      if (pdf != null) c.replaceWithPdf(pdf);
    } on PdfOpenException catch (e) {
      if (!e.cancelled) {
        _toast(
          e.locked ? S.pdfLocked : (e.password ? S.pdfPassword : S.pdfInvalid),
        );
      }
    } catch (_) {
      _toast(S.pdfInvalid);
    }
  });

  Rect? _shareOrigin() {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _save() async {
    if (c.isCutting) return;
    try {
      if (c.isPdf) {
        final bytes = await c.buildPdfExport();
        if (bytes == null) return;
        final uri = await FilePicker.saveFile(
          fileName: '${ExportService.baseFileName()}.pdf',
          bytes: bytes,
          mimeType: 'application/pdf',
        );
        // su web il file viene scaricato senza conferma
        if (uri != null || kIsWeb) _toast(S.pdfSaved);
        return;
      }
      final file = await c.buildImageExport();
      if (file == null) return;
      final outcome = await c.exporter.saveToPhotos(file);
      _toast(switch (outcome) {
        SaveOutcome.saved => S.saved,
        SaveOutcome.denied => S.saveDenied,
        SaveOutcome.unavailable => S.saveUnavailable,
        SaveOutcome.failed => S.saveFailed,
      });
    } catch (_) {
      _toast(S.saveFailed);
    }
  }

  Future<void> _share() async {
    if (c.isCutting) return;
    try {
      bool ok;
      if (c.isPdf) {
        final bytes = await c.buildPdfExport();
        if (bytes == null) return;
        ok = await c.exporter.shareBytes(
          bytes,
          'application/pdf',
          '${ExportService.baseFileName()}.pdf',
          origin: _shareOrigin(),
        );
      } else {
        final file = await c.buildImageExport();
        if (file == null) return;
        ok = await c.exporter.share(file, origin: _shareOrigin());
      }
      if (!ok) _toast(S.shareFailed);
    } catch (_) {
      _toast(S.shareFailed);
    }
  }

  Future<void> _applyToAll() async {
    final mode = c.previewLayout?.mode;
    if (mode == null || mode == PdfLayoutMode.custom) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(S.applyToAllTitle),
        content: Text(S.applyToAllBody(mode.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.apply),
          ),
        ],
      ),
    );
    if (ok == true) c.applyLayoutToAllModified(mode);
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
            const Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: BrandMark(size: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              key: _shareKey,
              width: 122,
              child: AppButton(
                label: S.share,
                icon: const Icon(Icons.ios_share),
                height: 40,
                fontSize: 14,
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
          child: EditorViewport(controller: c, frames: _frames),
        ),
        const SizedBox(height: 8),
        ..._bottom(),
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
          onApplyAll: c.pageCount > 1 ? _applyToAll : null,
        ),
      ];
    }
    final mode = c.selection.mode;
    final selVisible = c.selectionVisible;
    return [
      if (c.isPdf) ...[_pdfBar(), const SizedBox(height: 8)],
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
            child: SmashToggle(value: c.smashEnabled, onChanged: c.setSmash),
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
          'Pagina precedente',
        ),
        const SizedBox(width: 6),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            S.pageOf(c.pageIndex + 1, c.pageCount),
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 6),
        arrow(
          Icons.chevron_right,
          nav && c.pageIndex < c.pageCount - 1
              ? () => c.goToPage(c.pageIndex + 1)
              : null,
          'Pagina successiva',
        ),
        const Spacer(),
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
          const Row(
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
          const Text(
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
