import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../editor/application/editor_controller.dart';

/// Dopo lo spruzzo, gocce d'inchiostro (del colore usato) schizzano fuori dal
/// rettangolo e volano verso la testa nel contatore dei litri, come le
/// macerie di SMASH verso i kg. Quando arriva l'ultima: [onArrive].
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

  /// Una goccia è arrivata (per il "tic" e il saltello del contatore).
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

class _InkFlightOverlayState extends State<InkFlightOverlay>
    with SingleTickerProviderStateMixin {
  static List<ui.Image>? _imgs;
  static bool _loading = false;

  late final Ticker _ticker;
  final List<_Drop> _drops = [];
  int _seen = 0;
  double _t = 0;
  double _litres = 0;
  Color _color = Colors.black;
  bool _done = true;

  static const _fly = 1.15; // secondi fino all'ultima goccia

  EditorController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    c.addListener(_check);
    _seen = c.octoFlightId;
    _loadImages();
  }

  static Future<void> _loadImages() async {
    if (_imgs != null || _loading) return;
    _loading = true;
    try {
      _imgs = await Future.wait([
        for (var i = 1; i <= 6; i++)
          () async {
            final d = await rootBundle.load('assets/octo/gocce/goccia_$i.webp');
            final codec = await ui.instantiateImageCodec(
              d.buffer.asUint8List(),
            );
            final img = (await codec.getNextFrame()).image;
            codec.dispose();
            return img;
          }(),
      ]);
    } catch (_) {
      _loading = false;
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

  void _check() {
    final f = c.octoFlight;
    if (c.octoFlightId == _seen || f == null) return;
    _seen = c.octoFlightId;
    if (!_done) widget.onArrive(_litres); // volo precedente non finito
    final from = _local(widget.viewportKey, c.contentToScreen(f.center));
    if (from == null) {
      widget.onArrive(f.litres);
      return;
    }
    final rnd = math.Random(c.octoFlightId);
    // più inchiostro, più gocce (da 8 a 18)
    final n = (8 + f.litres * 20).clamp(8, 18).round();
    _drops
      ..clear()
      ..addAll([
        for (var k = 0; k < n; k++)
          _Drop(
            from +
                Offset(
                  (rnd.nextDouble() - .5) * f.width * .7,
                  (rnd.nextDouble() - .5) * f.height * .7,
                ),
            Offset.fromDirection(
              -math.pi / 2 + (rnd.nextDouble() - .5) * math.pi * 1.4,
              90 + rnd.nextDouble() * 120,
            ),
            16 + rnd.nextDouble() * 14,
            (rnd.nextDouble() - .5) * 8,
            rnd.nextInt(6),
            rnd.nextDouble() * .25,
          ),
      ]);
    _litres = f.litres;
    _color = Color(f.color);
    _done = false;
    _t = 0;
    _ticker
      ..stop()
      ..start();
  }

  void _tick(Duration d) {
    _t = d.inMicroseconds / 1e6;
    final target = _local(widget.targetKey, const Offset(14, 14));
    if (target != null) {
      for (final p in _drops) {
        if (!p.arrived && _progress(p) >= 1) {
          p.arrived = true;
          widget.onDrop();
        }
      }
    }
    if (_t >= _fly + .1) {
      _ticker.stop();
      _drops.clear();
      if (!_done) {
        _done = true;
        widget.onArrive(_litres);
      }
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
    if (_drops.isEmpty || _imgs == null) return const SizedBox.shrink();
    final target = _local(widget.targetKey, const Offset(14, 14));
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FlightPainter(
          drops: _drops,
          t: _t,
          target: target,
          imgs: _imgs!,
          color: _color,
          progress: _progress,
        ),
      ),
    );
  }
}

class _FlightPainter extends CustomPainter {
  _FlightPainter({
    required this.drops,
    required this.t,
    required this.target,
    required this.imgs,
    required this.color,
    required this.progress,
  });

  final List<_Drop> drops;
  final double t;
  final Offset? target;
  final List<ui.Image> imgs;
  final Color color;
  final double Function(_Drop) progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..colorFilter = ColorFilter.mode(color, BlendMode.modulate);
    for (final p in drops) {
      if (p.arrived) continue;
      // schizzo: esce dal rettangolo e rallenta
      final b = math.min(t, .32 + p.delay);
      final out = p.from + p.burst * b + Offset(0, 260 * b * b);
      final k = Curves.easeInCubic.transform(progress(p));
      final to = target ?? out;
      // volo a parabola verso il contatore
      final pos =
          Offset.lerp(out, to, k)! + Offset(0, -math.sin(k * math.pi) * 60);
      final s = p.size * (1 - .45 * k);
      final img = imgs[p.image];
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FlightPainter old) => true;
}
