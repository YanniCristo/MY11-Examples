import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Le immagini degli effetti d'inchiostro di un colore: gocce (A), macchie
/// (B), colature (C), pozza (E) e scritte fumetto (F).
///
/// Inchiostro nero → set nero, bianco → set bianco (così restano lucidi);
/// qualunque altro colore → set grigio da colorare ([tint] = true).
class InkFx {
  InkFx._(
    this.set,
    this.drops,
    this.blobs,
    this.drips,
    this.puddle,
    this.words,
  );

  final String set;
  final List<ui.Image> drops, blobs, drips, words;
  final ui.Image puddle;

  bool get tint => set == 'colore';

  static final Map<String, InkFx> _cache = {};
  static final Map<String, Future<InkFx?>> _loading = {};

  /// Quale set usare per un inchiostro.
  static String setFor(Color c) {
    final l = c.computeLuminance();
    if (l < .02) return 'nero';
    if (l > .85) return 'bianco';
    return 'colore';
  }

  static InkFx? ready(Color c) => _cache[setFor(c)];

  static Future<InkFx?> load(Color c) {
    final s = setFor(c);
    return _loading[s] ??= _load(s).then((v) {
      if (v != null) _cache[s] = v;
      return v;
    });
  }

  static Future<ui.Image> image(String path) async {
    final d = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(d.buffer.asUint8List());
    final img = (await codec.getNextFrame()).image;
    codec.dispose();
    return img;
  }

  static Future<InkFx?> _load(String s) async {
    try {
      final b = 'assets/octo/fx/$s';
      // le scritte: arcobaleno con i colori, arancioni con bianco e nero
      final w = s == 'colore' ? 'scritte_colore' : 'scritte';
      final r = await Future.wait([
        for (var i = 1; i <= 6; i++) image('$b/A$i.webp'),
        for (var i = 1; i <= 3; i++) image('$b/B$i.webp'),
        for (var i = 1; i <= 3; i++) image('$b/C$i.webp'),
        image('$b/E1.webp'),
        for (final x in const ['splash', 'splat', 'plic', 'slurp'])
          image('assets/octo/fx/$w/$x.webp'),
      ]);
      return InkFx._(
        s,
        r.sublist(0, 6),
        r.sublist(6, 9),
        r.sublist(9, 12),
        r[12],
        r.sublist(13),
      );
    } catch (_) {
      _loading.remove(s);
      return null;
    }
  }
}

/// Disegna [img] nel rettangolo [dst] (eventualmente colorato e trasparente).
void drawInk(
  Canvas canvas,
  ui.Image img,
  Rect dst, {
  Color? tint,
  double opacity = 1,
}) {
  if (opacity <= 0) return;
  final p = Paint()..filterQuality = FilterQuality.medium;
  if (tint != null) {
    p.colorFilter = ColorFilter.mode(
      tint.withValues(alpha: opacity),
      BlendMode.modulate,
    );
  } else if (opacity < 1) {
    p.color = Color.fromRGBO(0, 0, 0, opacity);
  }
  canvas.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    dst,
    p,
  );
}
