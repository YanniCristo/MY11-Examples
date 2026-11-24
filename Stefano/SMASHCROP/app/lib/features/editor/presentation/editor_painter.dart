import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../animation/domain/smash_config.dart';
import '../application/editor_controller.dart';
import '../domain/cut_operation.dart';

/// Disegna il documento (e il foglio, per i PDF) e, durante un taglio,
/// l'intera scena: le parti che si ricongiungono, la fascia che si rompe e
/// SMASH. Tutto resta dentro il viewport.
class EditorPainter extends CustomPainter {
  EditorPainter(this.c, this.frames)
    : super(repaint: Listenable.merge([c, c.frameTick]));

  final EditorController c;
  final List<ui.Image>? frames;

  static final _docPaint = Paint()..filterQuality = FilterQuality.medium;
  static final _pagePaint = Paint()..color = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    if (!c.pageReady) return;
    final a = c.animation;
    if (a == null || a.committed) {
      final f = c.frame;
      final t = c.transform;
      if (c.isPdf) _paintSheet(canvas, t.regionToScreen(Offset.zero & f.size));
      final d = c.doc;
      final dst = t.regionToScreen(f.contentRect);
      c.view.draw(
        canvas,
        Rect.fromLTWH(0, 0, d.width.toDouble(), d.height.toDouble()),
        dst,
        _docPaint,
      );
      if (c.positioning) {
        canvas.drawRect(
          dst.deflate(1),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = AppColors.red,
        );
      }
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
    final o0 = a.frame0.contentOffset, o1 = a.frame1.contentOffset;
    Rect at0(Rect r) => a.t0.regionToScreen(r.shift(o0));
    Rect at1(Rect r) => a.t1.regionToScreen(r.shift(o1));

    // il foglio PDF passa dalle dimensioni di prima a quelle di dopo
    if (c.isPdf) {
      final sheet0 = a.t0.regionToScreen(Offset.zero & a.frame0.size);
      final sheet1 = a.t1.regionToScreen(Offset.zero & a.frame1.size);
      _paintSheet(canvas, Rect.lerp(sheet0, sheet1, k)!);
    }

    // le due parti conservate: ferme fino al ricongiungimento, poi si
    // avvicinano fino alla posizione finale
    final List<(Rect, Rect, Rect)> parts =
        op.orientation == CutOrientation.horizontal
        ? [
            (
              Rect.fromLTWH(0, 0, w, s),
              at0(Rect.fromLTWH(0, 0, w, s)),
              at1(Rect.fromLTWH(0, 0, w, s)),
            ),
            (
              Rect.fromLTWH(0, e, w, h - e),
              at0(Rect.fromLTWH(0, e, w, h - e)),
              at1(Rect.fromLTWH(0, s, w, h - e)),
            ),
          ]
        : [
            (
              Rect.fromLTWH(0, 0, s, h),
              at0(Rect.fromLTWH(0, 0, s, h)),
              at1(Rect.fromLTWH(0, 0, s, h)),
            ),
            (
              Rect.fromLTWH(e, 0, w - e, h),
              at0(Rect.fromLTWH(e, 0, w - e, h)),
              at1(Rect.fromLTWH(s, 0, w - e, h)),
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
        at0(stripSrc),
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

  void _paintSheet(Canvas canvas, Rect r) {
    canvas.drawRect(
      r.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawRect(r, _pagePaint);
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
