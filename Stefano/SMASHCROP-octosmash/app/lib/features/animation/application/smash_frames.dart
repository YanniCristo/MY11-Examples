import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../domain/smash_config.dart';

/// Carica una volta i 18 frame ufficiali di SMASH.
class SmashFrames {
  SmashFrames._(this.frames);

  final List<ui.Image> frames;

  static Future<SmashFrames>? _loading;

  static Future<SmashFrames> load() => _loading ??= _load();

  static Future<SmashFrames> _load() async {
    final out = <ui.Image>[];
    for (var i = 0; i < SmashSprite.frameCount; i++) {
      final data = await rootBundle.load(SmashSprite.asset(i));
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      out.add((await codec.getNextFrame()).image);
      codec.dispose();
    }
    return SmashFrames._(out);
  }
}
