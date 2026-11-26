import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Il tocco di ogni skin sopra la base comune (vetro che si rompe + elementi
/// che volano al contatore). Tutto disegnato in codice: niente immagini in più.
///
/// [sec] = secondi dal colpo (Burp usa anche i 0,22 s prima del colpo).
/// [power] cresce con le macerie del taglio: 0,6 per un taglio piccolo,
/// fino a 1,3 per uno grande.
class SkinEffects {
  SkinEffects._();

  /// Fin dove l'effetto disegna (secondi dal colpo).
  static const double start = -0.22, end = 1.05;

  /// Forza dell'effetto in base ai kg del taglio.
  static double powerFor(double kg) =>
      (0.6 + 0.22 * math.log(1 + kg * 4) / math.ln2).clamp(0.6, 1.3);

  /// Spostamento dello schermo al pugno di SMASH (solo lui trema).
  static Offset shake(String skinId, double sec, double power) {
    if (skinId != 'smash' || sec < 0 || sec > .18) return Offset.zero;
    final k = 1 - sec / .18;
    return Offset(math.sin(sec * 95) * 3.2, math.cos(sec * 70) * 1.6) *
        k *
        power;
  }

  static void paint(
    Canvas c, {
    required String skinId,
    required Rect strip,
    required Offset impact,
    required double sec,
    required double power,
    required int seed,
  }) {
    if (sec < start || sec > end) return;
    final r = _Rnd(seed);
    switch (skinId) {
      case 'smash':
        _smash(c, strip, impact, sec, power, r);
      case 'burp':
        _burp(c, strip, impact, sec, power, r);
      case 'popcorn':
        _popcorn(c, strip, impact, sec, power, r);
      case 'muahaha':
        _muahaha(c, strip, impact, sec, power, r);
      case 'mammamia':
        _mammamia(c, strip, impact, sec, power, r);
      case 'tycoon':
        _tycoon(c, strip, impact, sec, power, r);
    }
  }

  static double _fade(double t, double from, double to) =>
      t <= from ? 1 : (1 - (t - from) / (to - from)).clamp(0.0, 1.0);

  static Color _a(Color col, double alpha) =>
      col.withValues(alpha: col.a * alpha.clamp(0.0, 1.0));

  static Offset _rand(_Rnd r, Rect s) =>
      Offset(s.left + r() * s.width, s.top + r() * s.height);

  // --- SMASH: onda d'urto + polvere ------------------------------------------

  static void _smash(Canvas c, Rect s, Offset o, double t, double p, _Rnd r) {
    if (t < 0) return;
    final maxR = (s.longestSide * .35).clamp(60.0, 170.0) * p;
    for (final (delay, col) in [
      (0.0, const Color(0xFFFFF3B0)),
      (.07, const Color(0xFFFFFFFF)),
    ]) {
      final k = ((t - delay) / .45).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final e = Curves.easeOutCubic.transform(k);
      c.drawCircle(
        o,
        12 + (maxR - 12) * e,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7 * (1 - e) + 1
          ..color = _a(col, .85 * (1 - k)),
      );
    }
    final dust = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final n = (10 * p).round();
    for (var i = 0; i < n; i++) {
      final at = _rand(r, s);
      final drift = Offset((r() - .5) * 70, -30 - r() * 60);
      final size = (14 + r() * 18) * p;
      final k = (t / .95).clamp(0.0, 1.0);
      dust.color = _a(const Color(0xFFBDB6A8), .5 * _fade(k, .3, 1));
      c.drawCircle(at + drift * k, size * (.5 + k), dust);
    }
  }

  // --- Burp: bolla di gomma che scoppia + gas verde con bollicine ------------

  static void _burp(Canvas c, Rect s, Offset o, double t, double p, _Rnd r) {
    final bubbleR = (s.shortestSide * 1.1).clamp(40.0, 80.0) * p;
    if (t < 0) {
      // la gomma si gonfia sopra la fascia
      final k = Curves.easeOut.transform(((t - start) / -start).clamp(0, 1));
      final rad = bubbleR * k;
      c.drawCircle(o, rad, Paint()..color = const Color(0xCCFF8FC8));
      c.drawCircle(
        o,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFE35BA0),
      );
      c.drawCircle(
        o + Offset(-rad * .35, -rad * .4),
        rad * .18,
        Paint()..color = const Color(0xAAFFFFFF),
      );
      return;
    }
    // scoppio: brandelli rosa che volano via
    if (t < .3) {
      final k = t / .3;
      final shred = Paint()..color = _a(const Color(0xFFFF8FC8), 1 - k);
      for (var i = 0; i < 8; i++) {
        final ang = i * math.pi / 4 + .3;
        final at = o + Offset.fromDirection(ang, bubbleR * (1 + 1.2 * k));
        c.drawOval(
          Rect.fromCenter(center: at, width: 14 * (1 - k * .5), height: 7),
          shred,
        );
      }
    }
    // nuvola di gas verde che sale
    final gas = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final k = (t / 1.0).clamp(0.0, 1.0);
    for (var i = 0; i < (7 * p).round(); i++) {
      final at = o + Offset((r() - .5) * s.width * .5, (r() - .5) * 30);
      final rise = Offset((r() - .5) * 40, -50 - r() * 60) * k;
      gas.color = _a(const Color(0xFF9BC21A), .45 * _fade(k, .35, 1));
      c.drawCircle(at + rise, (22 + r() * 22) * p * (.6 + .8 * k), gas);
    }
    // bollicine che salgono e scoppiano
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < (10 * p).round(); i++) {
      final at = _rand(r, s);
      final popAt = .35 + r() * .55;
      final size = 5 + r() * 8;
      final wob = r() * 6;
      if (t > popAt + .1) continue;
      final pos =
          at + Offset(math.sin(t * 12 + wob) * 6, -110 * math.min(t, popAt));
      if (t < popAt) {
        ring.color = const Color(0xDDCFF27A);
        c.drawCircle(pos, size, ring);
        c.drawCircle(
          pos + Offset(-size * .35, -size * .35),
          size * .25,
          Paint()..color = const Color(0xCCFFFFFF),
        );
      } else {
        final q = (t - popAt) / .1;
        ring.color = _a(const Color(0xFFCFF27A), 1 - q);
        c.drawCircle(pos, size * (1 + q), ring);
      }
    }
  }

  // --- Popcorn: chicchi che saltano e scoppiano ------------------------------

  static void _popcorn(Canvas c, Rect s, Offset o, double t, double p, _Rnd r) {
    if (t < 0) return;
    final n = (13 * p).round();
    for (var i = 0; i < n; i++) {
      final at = _rand(r, s);
      final v = Offset((r() - .5) * 260, -380 - r() * 280);
      final popAt = .1 + r() * .22;
      final size = (13 + r() * 7) * p.clamp(.8, 1.2);
      final spin = (r() - .5) * 8;
      final seedShape = r();
      final pos = at + v * t + Offset(0, 900 * t * t);
      final alpha = _fade(t, .8, 1.05);
      if (alpha <= 0) continue;
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(spin * t);
      if (t < popAt) {
        // chicco giallo
        c.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 8, height: 10),
          Paint()..color = _a(const Color(0xFFF2B21B), alpha),
        );
      } else {
        // lampo dello scoppio
        final q = (t - popAt) / .08;
        if (q < 1) {
          c.drawCircle(
            Offset.zero,
            size * (.6 + q),
            Paint()..color = _a(const Color(0xFFFFFFFF), .7 * (1 - q)),
          );
        }
        final grow = q < 1 ? .5 + .5 * q : 1.0;
        _popcornShape(c, size * grow, seedShape, alpha);
      }
      c.restore();
    }
  }

  static void _popcornShape(Canvas c, double size, double v, double alpha) {
    final shade = Paint()..color = _a(const Color(0xFFE9D9A6), alpha);
    final fill = Paint()..color = _a(const Color(0xFFFFFBEF), alpha);
    const bumps = [
      Offset(-.35, -.2),
      Offset(.3, -.3),
      Offset(.05, .25),
      Offset(-.25, .3),
      Offset(.38, .15),
    ];
    for (final b in bumps) {
      c.drawCircle(b * size + const Offset(1.5, 2), size * .36, shade);
    }
    for (final b in bumps) {
      c.drawCircle(b * size, size * (.33 + v * .06), fill);
    }
    c.drawCircle(
      Offset(.05, .25) * size,
      size * .12,
      Paint()..color = _a(const Color(0xFFF2B21B), alpha),
    );
  }

  // --- Muahaha: fumo viola, pipistrelli, fantasmini, scintille ---------------

  static void _muahaha(Canvas c, Rect s, Offset o, double t, double p, _Rnd r) {
    if (t < 0) return;
    final k = (t / 1.0).clamp(0.0, 1.0);
    final smoke = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    for (var i = 0; i < (8 * p).round(); i++) {
      final at = _rand(r, s);
      final rise = Offset((r() - .5) * 50, -40 - r() * 70) * k;
      smoke.color = _a(const Color(0xFF8E2BD8), .42 * _fade(k, .4, 1));
      c.drawCircle(at + rise, (18 + r() * 20) * p * (.6 + .9 * k), smoke);
    }
    // scintille arancio zucca
    final spark = Paint();
    for (var i = 0; i < (14 * p).round(); i++) {
      final ang = r() * math.pi * 2;
      final sp = 160 + r() * 220;
      final pos =
          o + Offset.fromDirection(ang, sp * t) + Offset(0, 200 * t * t);
      spark.color = _a(const Color(0xFFFF9800), _fade(t, .35, .7));
      c.drawCircle(pos, 3.2 - 2 * k, spark);
    }
    // pipistrelli che volano via in alto
    for (var i = 0; i < (4 * p).round().clamp(3, 5); i++) {
      final dir = (i.isEven ? -1 : 1) * (.6 + r() * .8);
      final delay = r() * .12;
      final tt = (t - delay).clamp(0.0, 2.0);
      final pos =
          o + Offset(dir * 230 * tt, -260 * tt + math.sin(tt * 14 + i) * 10);
      _bat(
        c,
        pos,
        46 * p.clamp(.8, 1.15),
        math.sin(tt * 34 + i),
        _fade(t, .75, 1.05),
      );
    }
    // fantasmini simpatici che salgono ondeggiando
    for (var i = 0; i < 2; i++) {
      final side = i == 0 ? -1.0 : 1.0;
      final from = o + Offset(side * s.width * .18, 0);
      final pos =
          from + Offset(math.sin(t * 7 + i) * 14 + side * 30 * t, -150 * t);
      final grow = t < .15 ? t / .15 : 1.0;
      _ghost(c, pos, 34 * p.clamp(.8, 1.15) * grow, t, _fade(t, .7, 1.05));
    }
  }

  static void _bat(Canvas c, Offset at, double w, double flap, double alpha) {
    final paint = Paint()..color = _a(const Color(0xFF2A1640), alpha);
    final y = flap * w * .22;
    final wing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-w * .3, -w * .1 + y, -w * .5, -w * .05 + y)
      ..quadraticBezierTo(-w * .38, w * .05 + y * .5, -w * .3, w * .12)
      ..quadraticBezierTo(-w * .18, w * .02, -w * .1, w * .12)
      ..lineTo(w * .1, w * .12)
      ..quadraticBezierTo(w * .18, w * .02, w * .3, w * .12)
      ..quadraticBezierTo(w * .38, w * .05 + y * .5, w * .5, -w * .05 + y)
      ..quadraticBezierTo(w * .3, -w * .1 + y, 0, 0)
      ..close();
    c.save();
    c.translate(at.dx, at.dy);
    c.drawPath(wing, paint);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, w * .05),
        width: w * .2,
        height: w * .26,
      ),
      paint,
    );
    // occhietti
    final eye = Paint()..color = _a(const Color(0xFFFFD54F), alpha);
    c.drawCircle(Offset(-w * .04, 0), w * .025, eye);
    c.drawCircle(Offset(w * .04, 0), w * .025, eye);
    c.restore();
  }

  static void _ghost(Canvas c, Offset at, double w, double t, double alpha) {
    final h = w * 1.15;
    final path = Path()..moveTo(-w / 2, 0);
    path.arcToPoint(Offset(w / 2, 0), radius: Radius.circular(w / 2));
    path.lineTo(w / 2, h * .55);
    const waves = 3;
    for (var i = 0; i < waves; i++) {
      final x0 = w / 2 - i * w / waves;
      final x1 = x0 - w / waves;
      final dip = math.sin(t * 10 + i) * w * .06;
      path.quadraticBezierTo(
        (x0 + x1) / 2,
        h * .55 + w * .16 + dip,
        x1,
        h * .55,
      );
    }
    path.close();
    c.save();
    c.translate(at.dx, at.dy);
    c.drawPath(path, Paint()..color = _a(const Color(0xF2F4EEFF), alpha));
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _a(const Color(0xFFB9A3E0), alpha),
    );
    final eye = Paint()..color = _a(const Color(0xFF2A1640), alpha);
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-w * .15, 0),
        width: w * .12,
        height: w * .17,
      ),
      eye,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(w * .15, 0),
        width: w * .12,
        height: w * .17,
      ),
      eye,
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(0, w * .2),
        width: w * .14,
        height: w * .1,
      ),
      eye,
    );
    c.restore();
  }

  // --- Mamma Mia: pomodoro da cartone che si spiaccica, basilico, spaghetti --

  static const _tomato = Color(0xFFFF6A3D);
  static const _tomatoDark = Color(0xFFD9481F);

  static void _mammamia(
    Canvas c,
    Rect s,
    Offset o,
    double t,
    double p,
    _Rnd r,
  ) {
    if (t < 0) return;
    final size = (s.shortestSide * .8).clamp(34.0, 64.0) * p.clamp(.85, 1.2);
    final alpha = _fade(t, .5, .8);
    // il pomodoro salta fuori, ricade e si schiaccia come una frittella
    const up = .22, fall = .38;
    double y, sx, sy;
    if (t < up) {
      final k = Curves.easeOut.transform(t / up);
      y = -size * 1.3 * k;
      sx = sy = .5 + .5 * k;
    } else if (t < fall) {
      final k = Curves.easeIn.transform((t - up) / (fall - up));
      y = -size * 1.3 * (1 - k);
      sx = sy = 1;
    } else {
      final k = Curves.elasticOut.transform(((t - fall) / .25).clamp(0, 1));
      y = size * .15 * k;
      sx = 1 + .35 * k;
      sy = 1 - .3 * k;
    }
    if (alpha > 0) {
      c.save();
      c.translate(o.dx, o.dy + y);
      c.scale(sx, sy);
      _tomatoShape(c, size, alpha, squashed: t >= fall);
      c.restore();
    }
    // foglie di basilico
    for (var i = 0; i < (5 * p).round(); i++) {
      final ang = -math.pi / 2 + (r() - .5) * 2.6;
      final v = Offset.fromDirection(ang, 220 + r() * 200);
      final spin = (r() - .5) * 10;
      final pos = o + v * t + Offset(0, 700 * t * t);
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(spin * t);
      _leaf(c, 18 * p.clamp(.8, 1.2), _fade(t, .7, 1.05));
      c.restore();
    }
    // qualche spaghetto
    final pasta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;
    for (var i = 0; i < 3; i++) {
      final ang = -math.pi / 2 + (i - 1) * .8 + (r() - .5) * .3;
      final v = Offset.fromDirection(ang, 260 + r() * 120);
      final pos = o + v * t + Offset(0, 650 * t * t);
      final len = 46.0 * p.clamp(.8, 1.2);
      pasta.color = _a(const Color(0xFFF7D774), _fade(t, .7, 1.05));
      final path = Path()..moveTo(-len / 2, 0);
      for (var j = 1; j <= 6; j++) {
        final x = -len / 2 + len * j / 6;
        path.lineTo(x, math.sin(j * 1.4 + t * 18 + i) * 5);
      }
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate((r() - .5) * 2 + t * 4);
      c.drawPath(path, pasta);
      c.restore();
    }
  }

  static void _tomatoShape(
    Canvas c,
    double d,
    double alpha, {
    required bool squashed,
  }) {
    final body = Rect.fromCenter(
      center: Offset.zero,
      width: d,
      height: d * .88,
    );
    c.drawOval(body, Paint()..color = _a(_tomato, alpha));
    c.drawOval(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = _a(_tomatoDark, alpha),
    );
    // riflesso bianco: fa subito "cartone"
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-d * .2, -d * .18),
        width: d * .22,
        height: d * .14,
      ),
      Paint()..color = _a(const Color(0xCCFFFFFF), alpha),
    );
    if (squashed) {
      // si vedono i semini
      final seed = Paint()..color = _a(const Color(0xFFFFE9A8), alpha);
      for (var i = 0; i < 6; i++) {
        final ang = i * math.pi / 3 + .4;
        c.drawOval(
          Rect.fromCenter(
            center: Offset.fromDirection(ang, d * .22) + Offset(0, d * .06),
            width: d * .07,
            height: d * .045,
          ),
          seed,
        );
      }
    }
    // picciolo verde a stella
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final ang = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? d * .2 : d * .07;
      final pt = Offset(0, -d * .4) + Offset.fromDirection(ang, rad);
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    c.drawPath(star, Paint()..color = _a(const Color(0xFF3E9B2F), alpha));
    c.drawLine(
      Offset(0, -d * .42),
      Offset(d * .04, -d * .56),
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = _a(const Color(0xFF2E7D22), alpha),
    );
  }

  static void _leaf(Canvas c, double w, double alpha) {
    final leaf = Path()
      ..moveTo(-w / 2, 0)
      ..quadraticBezierTo(0, -w * .45, w / 2, 0)
      ..quadraticBezierTo(0, w * .45, -w / 2, 0)
      ..close();
    c.drawPath(leaf, Paint()..color = _a(const Color(0xFF43A047), alpha));
    c.drawLine(
      Offset(-w * .45, 0),
      Offset(w * .4, 0),
      Paint()
        ..strokeWidth = 1.2
        ..color = _a(const Color(0xFF2E7D32), alpha),
    );
  }

  // --- Tycoon: monete d'oro e coriandoli dorati ------------------------------

  static void _tycoon(Canvas c, Rect s, Offset o, double t, double p, _Rnd r) {
    if (t < 0) return;
    final n = (14 * p).round();
    for (var i = 0; i < n; i++) {
      final fromAbove = i.isEven;
      final Offset pos;
      if (fromAbove) {
        // pioggia dall'alto sulla fascia
        final x = s.left + r() * s.width;
        final delay = r() * .15;
        final tt = (t - delay).clamp(0.0, 2.0);
        pos =
            Offset(x, s.top - 140 - r() * 80) +
            Offset(0, 900 * tt * tt / 2 + 120 * tt);
      } else {
        final ang = -math.pi / 2 + (r() - .5) * 2.4;
        pos =
            o +
            Offset.fromDirection(ang, 300 + r() * 200) * t +
            Offset(0, 900 * t * t / 2);
      }
      final flip = math.cos(t * (10 + r() * 8) + i);
      _coin(c, pos, 26 * p.clamp(.85, 1.2), flip, _fade(t, .75, 1.05));
    }
    // coriandoli dorati
    for (var i = 0; i < (18 * p).round(); i++) {
      final ang = r() * math.pi * 2;
      final pos =
          o +
          Offset.fromDirection(ang, (140 + r() * 200) * t) +
          Offset(0, 260 * t * t);
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(t * (r() * 14));
      c.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 7,
          height: 4 * math.cos(t * 20 + i).abs() + 1,
        ),
        Paint()
          ..color = _a(
            i.isEven ? const Color(0xFFFFD54F) : const Color(0xFFFFF3B0),
            _fade(t, .6, 1),
          ),
      );
      c.restore();
    }
    // brillantini
    for (var i = 0; i < 5; i++) {
      final at = o + Offset((r() - .5) * s.width * .7, (r() - .5) * 60 - 30);
      final tw = math.sin(((t - r() * .3) / .35) * math.pi);
      if (tw <= 0) continue;
      _sparkle(c, at, 10 * tw * p, tw);
    }
  }

  static void _coin(Canvas c, Offset at, double d, double flip, double alpha) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(flip.abs().clamp(.12, 1.0), 1);
    final rect = Rect.fromCenter(center: Offset.zero, width: d, height: d);
    c.drawOval(rect, Paint()..color = _a(const Color(0xFFE8A317), alpha));
    c.drawOval(
      rect.deflate(d * .12),
      Paint()..color = _a(const Color(0xFFFFD54F), alpha),
    );
    c.drawOval(
      rect.deflate(d * .24),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _a(const Color(0xFFE8A317), alpha),
    );
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-d * .15, -d * .18),
        width: d * .2,
        height: d * .12,
      ),
      Paint()..color = _a(const Color(0xBBFFFFFF), alpha),
    );
    c.restore();
  }

  static void _sparkle(Canvas c, Offset at, double r, double alpha) {
    final path = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r)
      ..close();
    c.drawPath(path, Paint()..color = _a(const Color(0xFFFFFFFF), alpha));
  }
}

/// Numeri casuali ripetibili: lo stesso taglio disegna sempre lo stesso effetto.
class _Rnd {
  _Rnd(int seed) : _s = (seed & 0x7fffffff) | 1;
  int _s;
  double call() => (_s = _s * 16807 % 2147483647) / 2147483647;
}
