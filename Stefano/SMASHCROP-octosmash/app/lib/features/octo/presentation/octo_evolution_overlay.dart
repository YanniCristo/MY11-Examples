import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../domain/octo_chars.dart';
import 'ink_fx.dart';

/// "OctoSmash si è evoluto!": un enorme schizzo del colore dell'evoluzione
/// copre lo schermo, esplodono coriandoli e scintille, compare la posa del
/// nuovo OctoSmash col contenitore appena riempito. Alla fine l'inchiostro
/// cola via. Circa 3 secondi (un tocco chiude prima).
Future<void> showOctoEvolution(BuildContext context, OctoChar ch) {
  precacheImage(AssetImage('assets/octo/teste/${ch.id}_posa.webp'), context);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => _OctoEvolution(ch: ch),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class _OctoEvolution extends StatefulWidget {
  const _OctoEvolution({required this.ch});
  final OctoChar ch;

  @override
  State<_OctoEvolution> createState() => _OctoEvolutionState();
}

class _OctoEvolutionState extends State<_OctoEvolution>
    with SingleTickerProviderStateMixin {
  static const _len = 3.2;
  late final Ticker _ticker = createTicker((d) {
    setState(() => _t = d.inMicroseconds / 1e6);
    if (_t > _len && !_closing) _close();
  });
  double _t = 0;
  bool _closing = false;
  List<ui.Image>? _party; // 6 coriandoli + 6 scintille
  ui.Image? _d1, _d2;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    Future.wait([
          for (var i = 1; i <= 6; i++)
            InkFx.image('assets/octo/fx/festa/coriandolo_$i.webp'),
          for (var i = 1; i <= 6; i++)
            InkFx.image('assets/octo/fx/festa/scintilla_$i.webp'),
        ])
        .then((v) {
          if (mounted) setState(() => _party = v);
        })
        .catchError((_) {});
    InkFx.image('assets/octo/fx/colore/D1.webp')
        .then((v) {
          if (mounted) setState(() => _d1 = v);
        })
        .catchError((_) {});
    InkFx.image('assets/octo/fx/colore/D2.webp')
        .then((v) {
          if (mounted) setState(() => _d2 = v);
        })
        .catchError((_) {});
    InkFx.load(widget.ch.color);
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
    final ch = widget.ch;
    final pop = Curves.elasticOut.transform(((_t - .25) / .9).clamp(0.0, 1.0));
    final out = ((_t - (_len - .5)) / .5).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: _closing ? null : _close,
      child: Material(
        color: Colors.black.withValues(alpha: .7 * (1 - out)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _Party(
                  t: _t,
                  len: _len,
                  color: ch.color,
                  party: _party,
                  d1: _d1,
                  d2: _d2,
                  ink: InkFx.ready(ch.color),
                ),
              ),
            ),
            Center(
              child: Opacity(
                opacity: 1 - out,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      S.octoEvolvedTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 12)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // vivo: rimbalza, respira e ondeggia mentre spruzza
                    Transform.translate(
                      offset: Offset(0, -10 * math.sin(_t * 5).abs()),
                      child: Transform.rotate(
                        angle: .06 * math.sin(_t * 3.2),
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.diagonal3Values(
                            (.2 + .8 * pop) * (1 + .04 * math.sin(_t * 10)),
                            (.2 + .8 * pop) * (1 - .04 * math.sin(_t * 10)),
                            1,
                          ),
                          child: Container(
                            width: 230,
                            height: 230,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ch.color.withValues(alpha: .55),
                                  blurRadius: 90,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            // nelle pose il personaggio occupa poco più di un
                            // quarto della larghezza: si ingrandisce l'immagine
                            child: OverflowBox(
                              maxWidth: 700,
                              maxHeight: 451,
                              child: Image.asset(
                                'assets/octo/teste/${ch.id}_posa.webp',
                                width: 700,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ch.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: ch.color,
                        shadows: const [Shadow(blurRadius: 10)],
                      ),
                    ),
                    if (ch.goalImage != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(ch.goalImage!, height: 34),
                          const SizedBox(width: 8),
                          Text(
                            '${ch.goalName}  ${InkMathLabel.litres(ch.litres)}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              shadows: [Shadow(blurRadius: 8)],
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
            ),
          ],
        ),
      ),
    );
  }
}

/// "5 L", "1000 L".
abstract final class InkMathLabel {
  static String litres(double l) => '${l.round()} L';
}

class _Party extends CustomPainter {
  _Party({
    required this.t,
    required this.len,
    required this.color,
    required this.party,
    required this.d1,
    required this.d2,
    required this.ink,
  });

  final InkFx? ink;

  final double t, len;
  final Color color;
  final List<ui.Image>? party;
  final ui.Image? d1, d2;

  @override
  void paint(Canvas canvas, Size size) {
    Rect cover(ui.Image im) {
      final s = math.max(size.width / im.width, size.height / im.height);
      return Rect.fromCenter(
        center: size.center(Offset.zero),
        width: im.width * s,
        height: im.height * s,
      );
    }

    // lo schizzo: esplode, resta dietro (un po' trasparente), poi cola via
    final end = len - .7;
    if (t < end && d1 != null) {
      final k = Curves.easeOutBack.transform((t / .25).clamp(0.0, 1.0));
      final o = t < .45 ? 1.0 : (1 - (t - .45) / .4).clamp(.38, 1.0);
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(.25 + .9 * k);
      canvas.translate(-size.width / 2, -size.height / 2);
      drawInk(canvas, d1!, cover(d1!), tint: color, opacity: o);
      canvas.restore();
    } else if (t >= end && d2 != null) {
      final k = Curves.easeIn.transform(((t - end) / .7).clamp(0.0, 1.0));
      drawInk(
        canvas,
        d2!,
        cover(d2!).shift(Offset(0, size.height * .5 * k)),
        tint: color,
        opacity: .38 * (1 - k),
      );
    }

    // fontana d'inchiostro del suo colore: gocce che schizzano su dal
    // personaggio e ricadono, per tutta la festa
    final fx = ink;
    if (fx != null) {
      final c0 = Offset(size.width / 2, size.height * .47);
      final rr = math.Random(5);
      for (var i = 0; i < 70; i++) {
        final born = .3 + rr.nextDouble() * (len - 1.1);
        final dir = -math.pi / 2 + (rr.nextDouble() - .5) * 2.2;
        final v = 300 + rr.nextDouble() * 380;
        final s = 10 + rr.nextDouble() * 18;
        final img = rr.nextInt(6);
        final tt = t - born;
        if (tt < 0 || tt > 1.4) continue;
        final p =
            c0 +
            Offset(math.cos(dir), math.sin(dir)) * v * tt +
            Offset(0, 700 * tt * tt);
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(tt * 6 * (i.isEven ? 1 : -1));
        drawInk(
          canvas,
          fx.drops[img],
          Rect.fromCenter(center: Offset.zero, width: s, height: s),
          tint: fx.tint ? color : null,
          opacity: (1 - (tt - 1) / .4).clamp(0.0, 1.0),
        );
        canvas.restore();
      }
    }

    // coriandoli e scintille: due esplosioni dal centro
    final im = party;
    if (im == null) return;
    final c = Offset(size.width / 2, size.height * .42);
    final r = math.Random(11);
    for (var i = 0; i < 60; i++) {
      final delay = i < 34 ? .2 : .9;
      final tt = t - delay - r.nextDouble() * .1;
      final dir = r.nextDouble() * math.pi * 2;
      final v = 260 + r.nextDouble() * 420;
      final spin = (r.nextDouble() - .5) * 10;
      final s = 22 + r.nextDouble() * 22;
      final img = im[i % 12];
      if (tt < 0) continue;
      final drag = 1 - math.exp(-2.2 * tt); // rallenta
      final p =
          c +
          Offset(math.cos(dir), math.sin(dir)) * v * drag / 2.2 +
          Offset(0, 160 * tt * tt);
      if (p.dy > size.height + 40) continue;
      final a = (1 - (tt - 1.6) / .6).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(spin * tt);
      drawInk(
        canvas,
        img,
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        opacity: a,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Party old) => true;
}
