import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../application/editor_controller.dart';
import '../domain/cut_operation.dart';
import 'editor_painter.dart';

/// Area di lavoro: documento, linee A/B con maniglie fuori dall'immagine,
/// zoom con due dita e spostamento con un dito quando è ingrandito.
class EditorViewport extends StatefulWidget {
  const EditorViewport({
    super.key,
    required this.controller,
    required this.frames,
  });

  final EditorController controller;
  final List<ui.Image>? frames;

  @override
  State<EditorViewport> createState() => _EditorViewportState();
}

class _EditorViewportState extends State<EditorViewport> {
  final _key = GlobalKey();

  EditorController get c => widget.controller;

  Offset _local(Offset global) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global) ?? global;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: AppColors.viewport,
        child: LayoutBuilder(
          builder: (context, box) {
            c.setViewportSize(box.biggest);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (d) => c.gestureStart(d.localFocalPoint),
              onScaleUpdate: (d) => c.gestureUpdate(d.localFocalPoint, d.scale),
              child: Stack(
                key: _key,
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: EditorPainter(c, widget.frames),
                      ),
                    ),
                  ),
                  ..._selection(box.biggest),
                  if (!c.pageReady)
                    const Center(
                      child: SizedBox.square(
                        dimension: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _selection(Size size) {
    final mode = c.selection.mode;
    final pair = c.selection.active;
    if (!c.selectionVisible || mode == null || pair == null) return const [];
    final r = c.contentScreenRect;
    final horizontal = mode == CutOrientation.horizontal;
    double screen(double v) => horizontal
        ? c.contentToScreen(Offset(0, v)).dy
        : c.contentToScreen(Offset(v, 0)).dx;
    final pa = screen(pair.a), pb = screen(pair.b);
    final lo = pa < pb ? pa : pb, hi = pa < pb ? pb : pa;
    final out = <Widget>[
      // fascia oscurata ma trasparente: il contenuto resta visibile
      Positioned.fromRect(
        rect: horizontal
            ? Rect.fromLTRB(r.left, lo, r.right, hi)
            : Rect.fromLTRB(lo, r.top, hi, r.bottom),
        child: const IgnorePointer(
          child: ColoredBox(color: AppColors.selectionShade),
        ),
      ),
    ];
    for (final v in [pa, pb]) {
      out.add(
        Positioned.fromRect(
          rect: horizontal
              ? Rect.fromLTWH(r.left, v - 1.5, r.width, 3)
              : Rect.fromLTWH(v - 1.5, r.top, 3, r.height),
          child: const IgnorePointer(child: ColoredBox(color: AppColors.red)),
        ),
      );
    }
    // maniglie fuori dall'immagine: A a sinistra / in alto, B a destra / in basso
    const long = 42.0, short = 30.0, pad = 10.0;
    for (final (h, v) in [(LineHandle.a, pa), (LineHandle.b, pb)]) {
      final isA = h == LineHandle.a;
      final Rect rect;
      if (horizontal) {
        final x = isA
            ? (r.left - short - 1).clamp(1.0, size.width - short - 1)
            : (r.right + 1).clamp(1.0, size.width - short - 1);
        rect = Rect.fromLTWH(x.toDouble(), v - long / 2, short, long);
      } else {
        final y = isA
            ? (r.top - short - 1).clamp(1.0, size.height - short - 1)
            : (r.bottom + 1).clamp(1.0, size.height - short - 1);
        rect = Rect.fromLTWH(v - long / 2, y.toDouble(), long, short);
      }
      out.add(
        Positioned.fromRect(
          rect: rect.inflate(pad),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (_) => c.startLineDrag(h),
            onPointerMove: (e) => c.dragLineTo(_local(e.position)),
            onPointerUp: (_) => c.endLineDrag(),
            onPointerCancel: (_) => c.endLineDrag(),
            child: Padding(
              padding: const EdgeInsets.all(pad),
              child: _Handle(
                label: isA ? 'A' : 'B',
                horizontalMode: horizontal,
                active: c.draggingHandle == h,
              ),
            ),
          ),
        ),
      );
    }
    return out;
  }
}

class _Handle extends StatelessWidget {
  const _Handle({
    required this.label,
    required this.horizontalMode,
    required this.active,
  });

  final String label;
  final bool horizontalMode;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final children = [
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      // in orizzontale la linea si sposta su e giù, in verticale a destra e sinistra
      DoubleArrow(vertical: horizontalMode, size: 14, color: Colors.white),
    ];
    return Semantics(
      label: 'Linea $label',
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.redLight : AppColors.red,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: horizontalMode
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [children[0], const SizedBox(height: 3), children[1]],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [children[0], const SizedBox(width: 3), children[1]],
              ),
      ),
    );
  }
}
