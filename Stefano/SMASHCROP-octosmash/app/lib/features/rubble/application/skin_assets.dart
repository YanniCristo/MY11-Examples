import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../animation/domain/smash_config.dart';
import '../domain/skins.dart';

/// Disposizione di `atlas.webp` (uguale a tools/build_atlas.py): 18
/// fotogrammi in una griglia 5×4 con 2 px di bordo, e i 6 elementi in fila
/// nella cella 18. Un solo file per personaggio: una richiesta invece di 24.
abstract final class SkinAtlas {
  static const double fw = 730, fh = 470, pad = 2, cols = 5;
  static const double cw = fw + 2 * pad, ch = fh + 2 * pad;
  static const double ew = 96, egap = 4;

  static Rect frame(int i) =>
      Rect.fromLTWH((i % cols) * cw + pad, (i ~/ cols) * ch + pad, fw, fh);

  static Rect element(int i) =>
      Rect.fromLTWH(3 * cw + pad + i * (ew + egap), 3 * ch + pad, ew, ew);
}

/// Immagini di una skin pronte da disegnare: 18 fotogrammi e 6 elementi
/// della fascia. Si caricano una volta e restano in memoria.
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

  /// Carica in sottofondo, senza aspettare e senza errori.
  static void preload(SkinDef s) {
    load(s).then((_) {}, onError: (_) {});
  }

  static Future<SkinImages> _load(SkinDef s) async {
    final data = await rootBundle.load(s.atlas);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final atlas = (await codec.getNextFrame()).image;
    codec.dispose();
    ui.Image cut(Rect src) {
      final rec = ui.PictureRecorder();
      Canvas(rec).drawImageRect(
        atlas,
        src,
        Offset.zero & src.size,
        Paint()..filterQuality = FilterQuality.none,
      );
      final pic = rec.endRecording();
      final img = pic.toImageSync(src.width.round(), src.height.round());
      pic.dispose();
      return img;
    }

    final frames = [
      for (var i = 0; i < SmashSprite.frameCount; i++) cut(SkinAtlas.frame(i)),
    ];
    final elements = [for (var i = 0; i < 6; i++) cut(SkinAtlas.element(i))];
    atlas.dispose();
    return SkinImages(s, frames, elements);
  }
}
