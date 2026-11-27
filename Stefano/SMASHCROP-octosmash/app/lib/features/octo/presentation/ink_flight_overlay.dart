import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../editor/application/editor_controller.dart';
import 'ink_fx.dart';

/// Tutto quello che succede dopo lo spruzzo, come le macerie di SMASH:
/// - macchie d'inchiostro che esplodono sul rettangolo (B);
/// - una scritta fumetto, SPLASH! SPLAT! PLIC! SLURP! (F);
/// - colature che scendono dal bordo e finiscono in una pozza (C, E);
/// - gocce che schizzano fuori e volano fino alla testa nel contatore (A).
/// Quando arriva l'ultima goccia: [onArrive] con i litri.
class InkFlightOverlay extends StatefulWidget {
  const InkFlightOverlay({
    super.key,
    required this.controller,
    required this.viewportKey,
    required this.targetKey,
    required this.onArrive,
    required this.onDrop,
  });

  final EditorController controller;
  final GlobalKey viewportKey;

  /// La testa nel contatore dei litri.
  final GlobalKey targetKey;

  /// Tutto l'inchiostro è arrivato: si contano i litri.
  final void Function(double litres) onArrive;

  /// Una goccia è arrivata (per il saltello del contatore).
  final VoidCallback onDrop;

  @override
  State<InkFlightOverlay> createState() => _InkFlightOverlayState();
}

class _Drop {
  _Drop(this.from, this.burst, this.size, this.spin, this.image, this.delay);
  final Offset from, burst;
  final double size, spin, delay;
  final int image;
  bool arrived = false;
}

class _Blob {
  _Blob(this.at, this.size, this.angle, this.image, this.delay);
  final Offset at;
  final double size, angle, delay;
  final int image;
}

class _Drip {
  _Drip(this.x, this.width, this.length, this.image, this.delay);
  final double x, width, length, delay;
  final int image;
}

/// Uno schizzo che vola via dal rettangolo e poi cade per la gravità.
class _Fall {
  _Fall(this.from, this.v, this.size, this.image, this.spin, this.delay);
  final Offset from, v; // posizione iniziale e velocità (px/s)
  final double size, spin, delay;
  final int image;
}

class _Scene {
  _Scene(this.rect, this.color, this.litres);
  final Rect rect; // sullo schermo
  final Color color;
  final double litres;
  final drops = <_Drop>[];
  final blobs = <_Blob>[];
  final drips = <_Drip>[];
  final falls = <_Fall>[];
  int word = 0;
  double wordTilt = 0;
}

class _InkFlightOverlayState extends State<InkFlightOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  _Scene? _s;
  int _seen = 0;
  double _t = 0;
  bool _done = true;

  static const _fly = 1.15; // secondi fino all'ultima goccia
  static const _end = 2.4; // fine di colature, pozza e pioggia di schizzi

  EditorController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    c.addListener(_check);
    _seen = c.octoFlightId;
    // i tre set sono leggeri: si caricano subito
    for (final k in const [Colors.black, Colors.white, Colors.red]) {
      InkFx.load(k);
    }
  }

  @override
  void dispose() {
    c.removeListener(_check);
    _ticker.dispose();
    super.dispose();
  }

  Offset? _local(GlobalKey k, Offset p) {
    final me = context.findRenderObject() as RenderBox?;
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    if (me == null || box == null || !box.attached) return null;
    return me.globalToLocal(box.localToGlobal(p));
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onArrive(_s?.litres ?? 0);
  }

  void _check() {
    final f = c.octoFlight;
    if (c.octoFlightId == _seen || f == null) return;
    _seen = c.octoFlightId;
    _finish(); // volo precedente non ancora finito
    final hw = f.width / 2, hh = f.height / 2;
    final a = _local(
      widget.viewportKey,
      c.contentToScreen(f.center - Offset(hw, hh)),
    );
    final b = _local(
      widget.viewportKey,
      c.contentToScreen(f.center + Offset(hw, hh)),
    );
    if (a == null || b == null) {
      widget.onArrive(f.litres);
      return;
    }
    final r = Rect.fromPoints(a, b);
    final s = _Scene(r, Color(f.color), f.litres);
    final rnd = math.Random(c.octoFlightId);
    final side = math.min(r.width, r.height);

    // gocce: più inchiostro, più gocce (da 8 a 18)
    final n = (8 + f.litres * 20).clamp(8, 18).round();
    for (var k = 0; k < n; k++) {
      s.drops.add(
        _Drop(
          r.center +
              Offset(
                (rnd.nextDouble() - .5) * r.width * .7,
                (rnd.nextDouble() - .5) * r.height * .7,
              ),
          Offset.fromDirection(
            -math.pi / 2 + (rnd.nextDouble() - .5) * math.pi * 1.4,
            90 + rnd.nextDouble() * 120,
          ),
          18 + rnd.nextDouble() * 16,
          (rnd.nextDouble() - .5) * 8,
          rnd.nextInt(6),
          rnd.nextDouble() * .25,
        ),
      );
    }

    // macchie: 1 sui rettangoli piccoli, fino a 3 su quelli larghi
    final nb = (r.width / math.max(side, 1) / 1.6).clamp(1, 3).round();
    for (var k = 0; k < nb; k++) {
      final x = nb == 1 ? .5 : (k + .5) / nb;
      s.blobs.add(
        _Blob(
          Offset(
            r.left + r.width * x + (rnd.nextDouble() - .5) * 10,
            r.center.dy + (rnd.nextDouble() - .5) * r.height * .3,
          ),
          (side * 1.5).clamp(70, 230) * (.85 + rnd.nextDouble() * .3),
          rnd.nextDouble() * math.pi * 2,
          rnd.nextInt(3),
          k * .05,
        ),
      );
    }

    // colature dal bordo sotto: 2–4
    final nd = (r.width / 70).clamp(2, 4).round();
    for (var k = 0; k < nd; k++) {
      s.drips.add(
        _Drip(
          r.left + r.width * ((k + .3 + rnd.nextDouble() * .4) / nd),
          14 + rnd.nextDouble() * 10,
          50 + rnd.nextDouble() * 70,
          rnd.nextInt(3),
          .15 + rnd.nextDouble() * .2,
        ),
      );
    }
    // pioggia di schizzi: volano in ogni direzione (soprattutto in su e di
    // lato) anche lontano dal rettangolo, poi cadono verso il basso
    final screen = (context.findRenderObject() as RenderBox?)?.size;
    final reach = screen == null ? 500.0 : screen.longestSide;
    final nf = (26 + f.litres * 30).clamp(26, 44).round();
    for (var k = 0; k < nf; k++) {
      final dir = -math.pi / 2 + (rnd.nextDouble() - .5) * math.pi * 1.7;
      final speed = reach * (.35 + rnd.nextDouble() * .7);
      s.falls.add(
        _Fall(
          r.center +
              Offset(
                (rnd.nextDouble() - .5) * r.width * .8,
                (rnd.nextDouble() - .5) * r.height * .6,
              ),
          Offset.fromDirection(dir, speed),
          8 + math.pow(rnd.nextDouble(), 2) * 26,
          rnd.nextInt(6),
          (rnd.nextDouble() - .5) * 10,
          rnd.nextDouble() * .12,
        ),
      );
    }

    s.word = rnd.nextInt(4);
    s.wordTilt = (rnd.nextDouble() - .5) * .35;

    _s = s;
    _done = false;
    _t = 0;
    _ticker
      ..stop()
      ..start();
  }

  void _tick(Duration d) {
    _t = d.inMicroseconds / 1e6;
    final s = _s;
    if (s != null) {
      for (final p in s.drops) {
        if (!p.arrived && _progress(p) >= 1) {
          p.arrived = true;
          widget.onDrop();
        }
      }
      if (_t >= _fly + .1) _finish();
    }
    if (_t >= _end) {
      _ticker.stop();
      _s = null;
    }
    setState(() {});
  }

  /// 0 → appena partita, 1 → arrivata al contatore.
  double _progress(_Drop p) {
    final start = .32 + p.delay; // prima schizza fuori, poi vola
    return ((_t - start) / (_fly - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final fx = s == null ? null : InkFx.ready(s.color);
    if (s == null || fx == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FxPainter(
          s: s,
          fx: fx,
          t: _t,
          target: _local(widget.targetKey, const Offset(14, 14)),
          progress: _progress,
        ),
      ),
    );
  }
}

class _FxPainter extends CustomPainter {
  _FxPainter({
    required this.s,
    required this.fx,
    required this.t,
    required this.target,
    required this.progress,
  });

  final _Scene s;
  final InkFx fx;
  final double t;
  final Offset? target;
  final double Function(_Drop) progress;

  Color? get tint => fx.tint ? s.color : null;

  /// Verso in cui "punta" ogni forma di goccia (null: gira su sé stessa).
  static const List<double?> _heading = [
    math.pi * .75, // A1 lacrima: testa in basso a sinistra
    null, // A2 schizzo
    math.pi, // A3 striscia
    math.pi / 2, // A4 gocce: testa in basso
    null, // A5 pallina
    null, // A6 ricciolo
  ];

  static double _fade(double t, double from, double to) =>
      (1 - (t - from) / (to - from)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final r = s.rect;

    // colature: scendono dal bordo sotto e finiscono in una pozza
    var deepest = 0.0, deepX = r.center.dx;
    for (final d in s.drips) {
      final k = Curves.easeOutCubic.transform(
        ((t - d.delay) / .8).clamp(0.0, 1.0),
      );
      if (k <= 0) continue;
      final h = d.length * k;
      if (h > deepest) {
        deepest = h;
        deepX = d.x;
      }
      // l'immagine è alta 3 volte la larghezza: si allunga col tempo
      drawInk(
        canvas,
        fx.drips[d.image],
        Rect.fromLTWH(d.x - d.width / 2, r.bottom - 4, d.width, h + d.width),
        tint: tint,
        opacity: _fade(t, 1.4, _InkFlightOverlayState._end),
      );
    }
    if (deepest > 30 && t > .75) {
      final k = Curves.easeOutBack.transform(((t - .75) / .3).clamp(0.0, 1.0));
      final w = 90 * k;
      drawInk(
        canvas,
        fx.puddle,
        Rect.fromCenter(
          center: Offset(deepX, r.bottom + deepest + 10),
          width: w,
          height: w * .375,
        ),
        tint: tint,
        opacity: _fade(t, 1.4, _InkFlightOverlayState._end),
      );
    }

    // macchie: esplodono sul rettangolo e svaniscono
    for (final b in s.blobs) {
      final tt = t - b.delay;
      if (tt <= 0) continue;
      final k = Curves.easeOutBack.transform((tt / .18).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(b.at.dx, b.at.dy);
      canvas.rotate(b.angle);
      drawInk(
        canvas,
        fx.blobs[b.image],
        Rect.fromCenter(
          center: Offset.zero,
          width: b.size * k,
          height: b.size * k,
        ),
        tint: tint,
        opacity: _fade(tt, .3, .65),
      );
      canvas.restore();
    }

    // la scritta fumetto, sopra il rettangolo
    if (t < 1.15) {
      final k = Curves.elasticOut.transform((t / .5).clamp(0.0, 1.0));
      final w = 150.0 * k;
      final top = math.max(r.top - 46, 40.0);
      canvas.save();
      canvas.translate(r.center.dx.clamp(80, size.width - 80), top);
      canvas.rotate(s.wordTilt);
      drawInk(
        canvas,
        fx.words[s.word],
        Rect.fromCenter(center: Offset.zero, width: w, height: w / 2),
        opacity: _fade(t, .85, 1.15),
      );
      canvas.restore();
    }

    // pioggia di schizzi: volano via e poi cadono verso il basso
    const g = 1400.0; // gravità, px/s²
    for (final f in s.falls) {
      final tt = t - f.delay;
      if (tt <= 0) continue;
      // un po' d'attrito nell'aria: rallentano mentre la gravità li tira giù
      final drag = (1 - math.exp(-2.5 * tt)) / 2.5;
      final pos = f.from + f.v * drag + Offset(0, .5 * g * tt * tt);
      if (pos.dy > size.height + 40) continue;
      final vel = f.v * math.exp(-2.5 * tt) + Offset(0, g * tt);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      // le gocce allungate puntano dove vanno, le altre girano
      final along = _heading[f.image];
      canvas.rotate(along == null ? f.spin * tt : vel.direction - along);
      drawInk(
        canvas,
        fx.drops[f.image],
        Rect.fromCenter(center: Offset.zero, width: f.size, height: f.size),
        tint: tint,
        opacity: _fade(tt, 1.7, 2.2),
      );
      canvas.restore();
    }

    // gocce: schizzano fuori, poi volano a parabola verso il contatore
    for (final p in s.drops) {
      if (p.arrived) continue;
      final b = math.min(t, .32 + p.delay);
      final out = p.from + p.burst * b + Offset(0, 260 * b * b);
      final k = Curves.easeInCubic.transform(progress(p));
      final to = target ?? out;
      final pos =
          Offset.lerp(out, to, k)! + Offset(0, -math.sin(k * math.pi) * 60);
      final sz = p.size * (1 - .45 * k);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      drawInk(
        canvas,
        fx.drops[p.image],
        Rect.fromCenter(center: Offset.zero, width: sz, height: sz),
        tint: tint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FxPainter old) => true;
}
