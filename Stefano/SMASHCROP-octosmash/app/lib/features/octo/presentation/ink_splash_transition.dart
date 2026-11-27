import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Passaggio a OctoSmash: un enorme schizzo d'inchiostro copre lo schermo,
/// sotto cambia modalità ([onCovered]), poi l'inchiostro cola via e scopre
/// OctoSmash pronto. In tutto poco più di un secondo.
abstract final class InkSplashTransition {
  static Future<void> play(BuildContext context, VoidCallback onCovered) {
    precacheImage(const AssetImage('assets/octo/fx/nero/D1.webp'), context);
    precacheImage(const AssetImage('assets/octo/fx/nero/D2.webp'), context);
    final done = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Splash(
        onCovered: onCovered,
        onDone: () {
          entry.remove();
          done.complete();
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return done.future;
  }
}

class _Splash extends StatefulWidget {
  const _Splash({required this.onCovered, required this.onDone});
  final VoidCallback onCovered, onDone;

  @override
  State<_Splash> createState() => _SplashState();
}

class _SplashState extends State<_Splash> with SingleTickerProviderStateMixin {
  // 0–0,22 s: lo schizzo esplode e copre; 0,22–0,45: fermo (sotto cambia);
  // 0,45–1,25: cola via verso il basso e svanisce
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..forward().whenComplete(widget.onDone);
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    _a.addListener(() {
      if (!_covered && _a.value >= .2) {
        _covered = true;
        widget.onCovered();
      }
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) {
          final t = _a.value * 1.25;
          final Widget img;
          if (t < .45) {
            final k = Curves.easeOutBack.transform((t / .22).clamp(0, 1));
            img = Transform.scale(
              scale: .2 + .95 * k,
              child: Image.asset(
                'assets/octo/fx/nero/D1.webp',
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            );
          } else {
            final k = Curves.easeIn.transform(((t - .45) / .8).clamp(0, 1));
            final h = MediaQuery.sizeOf(context).height;
            img = Opacity(
              opacity: 1 - k * k,
              child: Transform.translate(
                offset: Offset(0, h * .55 * k),
                child: Image.asset(
                  'assets/octo/fx/nero/D2.webp',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            );
          }
          return SizedBox.expand(child: img);
        },
      ),
    );
  }
}
