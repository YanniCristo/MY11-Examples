import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../animation/domain/smash_config.dart';
import '../domain/skins.dart';

/// Immagini di una skin pronte da disegnare: 18 fotogrammi e 6 elementi
/// della fascia. Si caricano una volta e restano in memoria (sono leggere).
class SkinImages {
  SkinImages(this.skin, this.frames, this.elements);
  final SkinDef skin;
  final List<ui.Image> frames;
  final List<ui.Image> elements;

  static final Map<String, Future<SkinImages>> _cache = {};

  static Future<SkinImages> load(SkinDef s) =>
      _cache[s.id] ??= _load(s).catchError((Object e) {
        _cache.remove(s.id);
        throw e;
      });

  static Future<ui.Image> _image(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final img = (await codec.getNextFrame()).image;
    codec.dispose();
    return img;
  }

  static Future<SkinImages> _load(SkinDef s) async {
    final frames = <ui.Image>[];
    for (var i = 0; i < SmashSprite.frameCount; i++) {
      frames.add(await _image(s.frame(i)));
    }
    final elements = <ui.Image>[];
    for (var i = 0; i < 6; i++) {
      elements.add(await _image(s.element(i)));
    }
    return SkinImages(s, frames, elements);
  }
}
