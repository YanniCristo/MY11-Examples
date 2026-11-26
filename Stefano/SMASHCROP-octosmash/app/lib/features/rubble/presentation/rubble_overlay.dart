import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../editor/application/editor_controller.dart';
import '../application/skin_assets.dart';
import 'skin_effects.dart';

/// Gli elementi della skin che esplodono dalla fascia a ogni colpo.
///
/// La maggior parte cade per gravità e sparisce sotto i pulsanti; 3-5 pezzi
/// si fermano a mezz'aria, si illuminano e volano a curva verso la testa
/// nel contatore ("calamita"). Quando arriva l'ultimo si contano le macerie.
class RubbleOverlay extends StatefulWidget {
  const RubbleOverlay({
    super.key,
    required this.controller,
    required this.images,
    required this.viewportKey,
    required this.targetKey,
    required this.bottomKey,
    required this.onImpact,
    required this.onArrive,
  });

  final EditorController controller;
  final SkinImages? images;
  final GlobalKey viewportKey;

  /// La testa nel contatore, dove volano i pezzi raccolti.
  final GlobalKey targetKey;

  /// I pulsanti in basso: chi cade sparisce dietro di loro.
  final GlobalKey bottomKey;
  final void Function(CutAnimation a) onImpact;
  final void Function(CutAnimation a) onArrive;

  /// Secondi dopo il colpo in cui l'ultimo pezzo arriva alla barra.
  static const double arriveAt = 1.12;

  @override
  State<RubbleOverlay> createState() => _RubbleOverlayState();
}

class _Particle {
  _Particle({
    required this.start,
    required this.velocity,
    required this.spin,
    required this.size,
    required this.image,
    required this.collected,
    required this.delay,
  });
  final Offset start;
  final Offset velocity;
  final double spin;
  final double size;
  final int image;
  final bool collected;
  final double delay;
}

class _Burst {
  _Burst(this.particles, this.impact);
  final List<_Particle> particles;
  final Offset impact;
}

class _RubbleOverlayState extends State<RubbleOverlay> {
  final _bursts = Expando<_Burst>();
  final _impactDone = Expando<bool>();

  @override
  void initState() {
    super.initState();
    widget.controller.frameTick.addListener(_tick);
  }

  @override
  void dispose() {
    widget.controller.frameTick.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    final a = widget.controller.animation;
    if (a == null || a.rubbleKg <= 0) return;
    final sec = (a.elapsedMs - a.timeline.impactMs) / 1000;
    if (sec >= 0 && _impactDone[a] != true) {
      _impactDone[a] = true;
      widget.onImpact(a);
    }
    if (sec >= RubbleOverlay.arriveAt && !a.rubbleCounted) {
      a.rubbleCounted = true;
      widget.onArrive(a);
    }
  }

  bool _reduceMotion = false;

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return IgnorePointer(
      child: CustomPaint(size: Size.infinite, painter: _RubblePainter(this)),
    );
  }

  Offset? _toLocal(GlobalKey k, {bool center = false, bool top = false}) {
    final me = context.findRenderObject() as RenderBox?;
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    if (me == null || box == null || !box.attached) return null;
    final p = center
        ? box.size.center(Offset.zero)
        : (top ? Offset.zero : Offset.zero);
    return me.globalToLocal(box.localToGlobal(p));
  }

  _Burst? burstFor(CutAnimation a) {
    final have = _bursts[a];
    if (have != null) return have;
    final origin = _toLocal(widget.viewportKey);
    final p = a.placement;
    if (origin == null || p == null || a.stripRect.isEmpty) return null;
    final strip = a.stripRect.shift(origin);
    final impact = p.impact + origin;
    var seed = a.hashCode | 1;
    double rnd() => (seed = seed * 16807 % 2147483647) / 2147483647;
    final n = (strip.width * strip.height / 2600).round().clamp(12, 28);
    final out = <_Particle>[];
    for (var i = 0; i < n; i++) {
      final s = Offset(
        strip.left + rnd() * strip.width,
        strip.top + rnd() * strip.height,
      );
      final dir = s - impact;
      final d = dir.distance == 0 ? const Offset(1, 0) : dir / dir.distance;
      final speed = 220 + rnd() * 420;
      out.add(
        _Particle(
          start: s,
          velocity: d * speed + Offset(60 + rnd() * 120, -260 - rnd() * 260),
          spin: (rnd() - .5) * 9,
          size: 24 + rnd() * 22,
          image: (rnd() * 6).floor() % 6,
          collected: false,
          delay: rnd() * .06,
        ),
      );
    }
    for (var i = 0; i < 4; i++) {
      final ang = -math.pi / 2 + (i - 1.5) * .7 + (rnd() - .5) * .3;
      out.add(
        _Particle(
          start: impact + Offset(math.cos(ang), math.sin(ang)) * 12,
          velocity: Offset(math.cos(ang), math.sin(ang)) * (120 + rnd() * 60),
          spin: (rnd() - .5) * 4,
          size: 34,
          image: i % 6,
          collected: true,
          delay: i * .05,
        ),
      );
    }
    return _bursts[a] = _Burst(out, impact);
  }
}

class _RubblePainter extends CustomPainter {
  _RubblePainter(this.s) : super(repaint: s.widget.controller.frameTick);
  final _RubbleOverlayState s;

  static final _imgPaint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final a = s.widget.controller.animation;
    final imgs = s.widget.images;
    if (a == null || a.rubbleKg <= 0 || imgs == null) return;
    final sec = (a.elapsedMs - a.timeline.impactMs) / 1000;
    if (sec < SkinEffects.start) return;
    final b = s.burstFor(a);
    if (b == null) return;
    // il tocco della skin (sotto agli elementi)
    if (!s._reduceMotion) {
      final origin = s._toLocal(s.widget.viewportKey);
      if (origin != null) {
        // come gli elementi: non passa sopra i pulsanti in basso
        final bottom = s._toLocal(s.widget.bottomKey)?.dy ?? size.height;
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, size.width, bottom));
        SkinEffects.paint(
          canvas,
          skinId: imgs.skin.id,
          strip: a.stripRect.shift(origin),
          impact: b.impact,
          sec: sec,
          power: SkinEffects.powerFor(a.rubbleKg),
          seed: a.hashCode,
        );
        canvas.restore();
      }
    }
    if (sec < 0) return;
    final target =
        s._toLocal(s.widget.targetKey, center: true) ?? const Offset(40, 20);
    final bottom = s._toLocal(s.widget.bottomKey)?.dy ?? size.height;

    // chi cade: sparisce dietro i pulsanti in basso
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, bottom));
    for (final p in b.particles) {
      if (p.collected) continue;
      final t = sec - p.delay;
      if (t < 0) continue;
      final pos = p.start + p.velocity * t + Offset(0, 1500 * t * t / 2);
      final alpha = t < 1.15 ? 1.0 : (1 - (t - 1.15) / .35).clamp(0.0, 1.0);
      if (alpha <= 0) continue;
      final grow = t < .08 ? .4 + .6 * t / .08 : 1.0;
      _draw(
        canvas,
        imgs.elements[p.image],
        pos,
        p.size * grow,
        p.spin * t,
        alpha,
      );
    }
    canvas.restore();

    // i pezzi raccolti: scoppio, pausa a mezz'aria con luce, volo a curva
    for (final p in b.particles) {
      if (!p.collected) continue;
      final t = sec - p.delay;
      if (t < 0) continue;
      const burst = .25, hover = .42, arrive = .95;
      final out = p.start + p.velocity * burst;
      if (t < burst) {
        final k = Curves.easeOut.transform(t / burst);
        _draw(
          canvas,
          imgs.elements[p.image],
          Offset.lerp(p.start, out, k)!,
          p.size * (.5 + .5 * k),
          p.spin * t,
          1,
        );
      } else if (t < hover) {
        final bob = math.sin((t - burst) * 30) * 2;
        _glow(canvas, out, p.size);
        _draw(
          canvas,
          imgs.elements[p.image],
          out + Offset(0, bob),
          p.size,
          p.spin * burst,
          1,
        );
      } else if (t < arrive) {
        final k = Curves.easeInCubic.transform((t - hover) / (arrive - hover));
        Offset at(double k) {
          final ctrl = Offset.lerp(out, target, .5)! + const Offset(60, -90);
          final u = 1 - k;
          return out * u * u + ctrl * 2 * u * k + target * k * k;
        }

        // scia dietro al pezzo
        for (var g = 3; g >= 1; g--) {
          final kg = (k - g * .07).clamp(0.0, 1.0);
          _draw(
            canvas,
            imgs.elements[p.image],
            at(kg),
            p.size * (1 - .45 * kg),
            0,
            .18 * (4 - g) / 3,
          );
        }
        _glow(canvas, at(k), p.size * (1 - .45 * k));
        _draw(
          canvas,
          imgs.elements[p.image],
          at(k),
          p.size * (1 - .45 * k),
          p.spin * burst * (1 - k),
          1,
        );
      }
    }
  }

  void _glow(Canvas c, Offset at, double size) {
    c.drawCircle(
      at,
      size * .75,
      Paint()
        ..color = const Color(0x66FFF3B0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _draw(
    Canvas c,
    ui.Image img,
    Offset at,
    double size,
    double rot,
    double alpha,
  ) {
    c.save();
    c.translate(at.dx, at.dy);
    if (rot != 0) c.rotate(rot);
    final p = alpha >= 1
        ? _imgPaint
        : (Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Color.fromRGBO(0, 0, 0, alpha));
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: size, height: size),
      p,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_RubblePainter old) => true;
}
