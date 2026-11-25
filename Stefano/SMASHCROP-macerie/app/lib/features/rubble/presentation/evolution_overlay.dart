import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../application/skin_assets.dart';
import '../domain/skins.dart';

/// "SMASH si è evoluto!": lo schermo si scurisce, piovono gli elementi del
/// nuovo personaggio su tutto lo schermo e compare la sua posa da eroe.
/// È l'unico effetto a tutto schermo; dura circa 2,5 secondi (un tocco lo
/// chiude prima).
Future<void> showEvolution(BuildContext context, SkinDef skin) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => _Evolution(skin: skin),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class _Evolution extends StatefulWidget {
  const _Evolution({required this.skin});
  final SkinDef skin;

  @override
  State<_Evolution> createState() => _EvolutionState();
}

class _EvolutionState extends State<_Evolution>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) {
    setState(() => _t = d.inMicroseconds / 1e6);
    if (_t > 2.6 && !_closing) _close();
  });
  double _t = 0;
  bool _closing = false;
  SkinImages? _imgs;

  @override
  void initState() {
    super.initState();
    SkinImages.load(widget.skin)
        .then((v) {
          if (mounted) setState(() => _imgs = v);
        })
        .catchError((_) {});
    _ticker.start();
  }

  void _close() {
    _closing = true;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = Curves.elasticOut.transform((_t / .9).clamp(0.0, 1.0));
    return GestureDetector(
      onTap: _closing ? null : _close,
      child: Material(
        color: Colors.black.withValues(alpha: .72),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _Rain(_imgs, _t))),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.evolvedTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: const [Shadow(blurRadius: 12)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Transform.scale(
                    scale: .2 + .8 * pop,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.skin.color.withValues(alpha: .55),
                            blurRadius: 90,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Image.asset(widget.skin.pose),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.skin.name,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: widget.skin.color,
                    ),
                  ),
                  if (widget.skin.goalImage != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(widget.skin.goalImage!, height: 30),
                        const SizedBox(width: 8),
                        Text(
                          widget.skin.goalLabel,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rain extends CustomPainter {
  _Rain(this.imgs, this.t);
  final SkinImages? imgs;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final im = imgs;
    if (im == null) return;
    final r = math.Random(7);
    final alpha = t < 2.1 ? 1.0 : (1 - (t - 2.1) / .5).clamp(0.0, 1.0);
    for (var i = 0; i < 46; i++) {
      final x = r.nextDouble() * size.width;
      final delay = r.nextDouble() * 1.2;
      final speed = 380 + r.nextDouble() * 420;
      final s = 26 + r.nextDouble() * 30;
      final tt = t - delay;
      if (tt < 0) continue;
      final y = -40 + speed * tt;
      if (y > size.height + 40) continue;
      final img = im.elements[i % 6];
      canvas.save();
      canvas.translate(x + math.sin(tt * 3 + i) * 18, y);
      canvas.rotate(tt * (r.nextDouble() - .5) * 6);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        Paint()..color = ui.Color.fromRGBO(0, 0, 0, alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Rain old) => true;
}
