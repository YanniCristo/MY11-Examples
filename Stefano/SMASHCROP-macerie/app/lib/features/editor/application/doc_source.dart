import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../domain/strip_document.dart';

/// Il documento attuale pronto da disegnare.
///
/// Di norma il risultato viene "appiattito" in una sola immagine alla
/// risoluzione reale ([flat]), copiando i pixel 1:1 dall'originale. Per
/// immagini oltre il limite delle texture si disegnano direttamente i blocchi
/// dell'originale.
class DocSource {
  DocSource._(this.original, this.doc, this.flat, this._ownsFlat);

  static const int maxFlatSide = 8192;

  final ui.Image original;
  final StripDocument doc;
  final ui.Image? flat;
  final bool _ownsFlat;

  factory DocSource.build(ui.Image original, StripDocument doc) {
    if (doc.width == original.width && doc.height == original.height) {
      return DocSource._(original, doc, original, false);
    }
    // nel browser niente copia appiattita: si disegnano i blocchi
    // dell'originale, così ogni pagina occupa la memoria una volta sola
    if (kIsWeb || doc.width > maxFlatSide || doc.height > maxFlatSide) {
      return DocSource._(original, doc, null, false);
    }
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (final t in doc.tiles()) {
      c.drawImageRect(
        original,
        Rect.fromLTWH(
          t[0].toDouble(),
          t[1].toDouble(),
          t[4].toDouble(),
          t[5].toDouble(),
        ),
        Rect.fromLTWH(
          t[2].toDouble(),
          t[3].toDouble(),
          t[4].toDouble(),
          t[5].toDouble(),
        ),
        p,
      );
    }
    final pic = rec.endRecording();
    try {
      final img = pic.toImageSync(doc.width, doc.height);
      return DocSource._(original, doc, img, true);
    } catch (_) {
      return DocSource._(original, doc, null, false);
    } finally {
      pic.dispose();
    }
  }

  /// Disegna la regione [src] del documento (in pixel) dentro [dst].
  void draw(Canvas canvas, Rect src, Rect dst, Paint paint) {
    if (src.isEmpty || dst.isEmpty) return;
    final f = flat;
    if (f != null) {
      canvas.drawImageRect(f, src, dst, paint);
      return;
    }
    final sx = dst.width / src.width;
    final sy = dst.height / src.height;
    final tiles = doc.tiles(
      x0: src.left.floor(),
      y0: src.top.floor(),
      x1: src.right.ceil(),
      y1: src.bottom.ceil(),
    );
    for (final t in tiles) {
      final d = Rect.fromLTWH(
        dst.left + (t[2] - src.left) * sx,
        dst.top + (t[3] - src.top) * sy,
        t[4] * sx,
        t[5] * sy,
      );
      canvas.drawImageRect(
        original,
        Rect.fromLTWH(
          t[0].toDouble(),
          t[1].toDouble(),
          t[4].toDouble(),
          t[5].toDouble(),
        ),
        d,
        paint,
      );
    }
  }

  void dispose() {
    if (_ownsFlat) flat?.dispose();
  }
}
