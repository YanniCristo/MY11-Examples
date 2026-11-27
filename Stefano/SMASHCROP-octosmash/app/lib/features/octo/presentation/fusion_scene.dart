import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../rubble/application/rubble_store.dart';
import '../../rubble/application/sound_fx.dart';

/// La scena in cui i 4 OctoSmash di base si fondono in OctoSmash Fusione:
/// 12 immagini a tutto schermo, l'ultima ("FUSIONE!") resta un attimo.
/// Un tocco la chiude.
class FusionScene extends StatefulWidget {
  const FusionScene({super.key});

  static Future<void> show(BuildContext context) async {
    await SoundFx.instance.prepareFusionScene();
    if (!context.mounted) return;
    // le immagini pronte prima di partire, così la scena non scatta
    for (var i = 1; i <= 12; i++) {
      precacheImage(AssetImage(_asset(i)), context);
    }
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xF20A0B10),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const FusionScene(),
    );
  }

  static String _asset(int i) =>
      'assets/octo/scena/fusione_${i.toString().padLeft(2, '0')}.webp';

  @override
  State<FusionScene> createState() => _FusionSceneState();
}

class _FusionSceneState extends State<FusionScene> {
  int _frame = 1;
  Timer? _timer;

  // tempi per fotogramma (ms): arrivo, cerchio, vortice, lampo, eroe
  static const _ms = [380, 300, 300, 380, 240, 200, 160, 160, 260, 260, 320];

  @override
  void initState() {
    super.initState();
    if (RubbleStore.instance.sound) SoundFx.instance.fusionScene();
    _next();
  }

  void _next() {
    if (_frame >= 12) {
      HapticFeedback.heavyImpact();
      _timer = Timer(const Duration(milliseconds: 1800), _close);
      return;
    }
    _timer = Timer(Duration(milliseconds: _ms[_frame - 1]), () {
      if (!mounted) return;
      setState(() => _frame++);
      if (_frame == 9) HapticFeedback.mediumImpact(); // lampo
      _next();
    });
  }

  void _close() {
    _timer?.cancel();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            FusionScene._asset(_frame),
            gaplessPlayback: true,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
