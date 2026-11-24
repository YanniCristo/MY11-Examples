import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../animation/domain/smash_config.dart';
import '../application/editor_controller.dart';
import '../domain/cut_operation.dart';

/// Disegna il documento e, durante un taglio, l'intera scena: le parti che
/// si ricongiungono, la fascia che si rompe e SMASH. Tutto resta dentro il
/// viewport.
class EditorPainter extends CustomPainter {
  EditorPainter(this.c, this.frames)
    : super(repaint: Listenable.merge([c, c.frameTick]));

  final EditorController c;
  final List<ui.Image>? frames;

  static final _docPaint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final a = c.animation;
    if (a == null || a.committed) {
      final t = c.transform;
      final d = c.doc;
      c.view.draw(
        canvas,
        Rect.fromLTWH(0, 0, d.width.toDouble(), d.height.toDouble()),
        t.contentRect,
        _docPaint,
      );
      if (a != null) _paintRobot(canvas, a);
      return;
    }

    final ms = a.elapsedMs;
    final tl = a.timeline;
    final op = a.op;
    final w = a.before.doc.width.toDouble();
    final h = a.before.doc.height.toDouble();
    final s = op.start.toDouble(), e = op.end.toDouble();
    final k = tl.joinProgress(ms);

    // le due parti conservate: ferme fino al ricongiungimento, poi si
    // avvicinano fino alla posizione finale
    final List<(Rect, Rect, Rect)> parts =
        op.orientation == CutOrientation.horizontal
        ? [
            (
              Rect.fromLTWH(0, 0, w, s),
              a.t0.regionToScreen(Rect.fromLTWH(0, 0, w, s)),
              a.t1.regionToScreen(Rect.fromLTWH(0, 0, w, s)),
            ),
            (
              Rect.fromLTWH(0, e, w, h - e),
              a.t0.regionToScreen(Rect.fromLTWH(0, e, w, h - e)),
              a.t1.regionToScreen(Rect.fromLTWH(0, s, w, h - e)),
            ),
          ]
        : [
            (
              Rect.fromLTWH(0, 0, s, h),
              a.t0.regionToScreen(Rect.fromLTWH(0, 0, s, h)),
              a.t1.regionToScreen(Rect.fromLTWH(0, 0, s, h)),
            ),
            (
              Rect.fromLTWH(e, 0, w - e, h),
              a.t0.regionToScreen(Rect.fromLTWH(e, 0, w - e, h)),
              a.t1.regionToScreen(Rect.fromLTWH(s, 0, w - e, h)),
            ),
          ];
    for (final (src, d0, d1) in parts) {
      if (src.isEmpty) continue;
      a.before.draw(canvas, src, Rect.lerp(d0, d1, k)!, _docPaint);
    }

    // la fascia intera (prima del pugno, o in dissolvenza senza SMASH)
    final stripSrc = op.orientation == CutOrientation.horizontal
        ? Rect.fromLTWH(0, s, w, e - s)
        : Rect.fromLTWH(s, 0, e - s, h);
    final alpha = tl.stripOpacity(ms);
    if (alpha > 0) {
      a.before.draw(
        canvas,
        stripSrc,
        a.t0.regionToScreen(stripSrc),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(0, 0, 0, alpha),
      );
    }

    // frammenti: solo la fascia selezionata si rompe
    final sec = tl.shatterSeconds(ms);
    if (sec != null) {
      final fade = (1 - sec * 1000 / tl.settings.shatterDuration.inMilliseconds)
          .clamp(0.0, 1.0);
      final p = Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(0, 0, 0, fade);
      for (final sh in a.shards) {
        final pos =
            sh.dst.center + sh.velocity * sec + Offset(0, 900 * sec * sec);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(sh.spin * sec);
        a.before.draw(
          canvas,
          sh.src,
          Rect.fromCenter(
            center: Offset.zero,
            width: sh.dst.width,
            height: sh.dst.height,
          ),
          p,
        );
        canvas.restore();
      }
    }

    _paintRobot(canvas, a);
  }

  void _paintRobot(Canvas canvas, CutAnimation a) {
    final p = a.placement;
    final f = a.timeline.frameAt(a.elapsedMs);
    final imgs = frames;
    if (p == null || f == null || imgs == null) return;
    final dx = a.timeline.robotDx(a.elapsedMs, p);
    final dst = (p.origin + Offset(dx, 0)) & p.frameSize;
    canvas.drawImageRect(
      imgs[f],
      Offset.zero & SmashSprite.frameSize,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(EditorPainter old) => old.c != c || old.frames != frames;
}
