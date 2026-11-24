import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand.dart';
import '../../animation/application/smash_frames.dart';
import '../../export/export_service.dart';
import '../../image_processing/services/image_loader.dart';
import '../../settings/preferences.dart';
import '../application/editor_controller.dart';
import '../domain/cut_operation.dart';
import '../domain/viewport_transform.dart';
import 'editor_viewport.dart';
import 'smash_toggle.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.image,
    required this.preferences,
  });

  final LoadedImage image;
  final AppPreferences preferences;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late final EditorController c;
  late final Ticker _ticker;
  final _loader = ImageLoader();
  final _shareKey = GlobalKey();
  List<ui.Image>? _frames;
  CutAnimation? _runningFor;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    c = EditorController(image: widget.image, preferences: widget.preferences);
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

  Future<void> _loadImage() async {
    if (_loading || c.isCutting) return;
    setState(() => _loading = true);
    try {
      final img = await _loader.pick();
      if (img != null) c.replaceImage(img);
    } on ImageLoadException catch (e) {
      _toast(e.tooLarge ? S.tooLarge : S.loadFailed);
    } catch (_) {
      _toast(S.loadFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final file = await _export();
    if (file == null) return;
    final outcome = await c.exporter.saveToPhotos(file);
    _toast(switch (outcome) {
      SaveOutcome.saved => S.saved,
      SaveOutcome.denied => S.saveDenied,
      SaveOutcome.unavailable => S.saveUnavailable,
      SaveOutcome.failed => S.saveFailed,
    });
  }

  Future<void> _share() async {
    final file = await _export();
    if (file == null) return;
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final ok = await c.exporter.share(file, origin: origin);
    if (!ok) _toast(S.shareFailed);
  }

  Future<ExportedFile?> _export() async {
    if (c.isCutting) return null;
    try {
      return await c.buildExport();
    } catch (_) {
      _toast(S.saveFailed);
      return null;
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
            if (_loading || c.busyExporting)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x99000000),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.red),
                        const SizedBox(height: 14),
                        Text(
                          c.busyExporting ? S.preparing : S.opening,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _layout() {
    final mode = c.selection.mode;
    final selVisible = c.selectionVisible;
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
                onPressed: c.isCutting ? null : _share,
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
                onPressed: c.isCutting ? null : _save,
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
                label: '${c.zoom.toStringAsFixed(1)}x',
                onChanged: c.isCutting ? null : c.setZoom,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: EditorViewport(controller: c, frames: _frames),
        ),
        const SizedBox(height: 10),
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
                onPressed: c.isCutting
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
                onPressed: c.isCutting
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
                dimmed: true,
                onPressed: () => _toast(S.pdfSoon),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
