import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart';

import '../../octo/domain/ink_fill.dart';
import '../domain/strip_document.dart';

/// Il documento attuale pronto da disegnare.
///
/// Di norma il risultato viene "appiattito" in una sola immagine alla
/// risoluzione reale ([flat]), copiando i pixel 1:1 dall'originale. Per
/// immagini oltre il limite delle texture si disegnano direttamente i blocchi
/// dell'originale.
class DocSource {
  DocSource._(
    this.original,
    this.doc,
    this.flat,
    this._ownsFlat, [
    this.fills = const [],
  ]);

  static const int maxFlatSide = 8192;

  final ui.Image original;
  final StripDocument doc;
  final ui.Image? flat;
  final bool _ownsFlat;

  /// Rettangoli d'inchiostro di OctoSmash (coordinate dell'originale).
  final List<InkFill> fills;

  static final _black = Paint()..color = const Color(0xFF000000);
  static final _white = Paint()..color = const Color(0xFFFFFFFF);

  /// Disegna gli inchiostri sopra un pezzo dell'originale: [src] è il pezzo
  /// nell'originale, [dst] dove finisce sullo schermo o nell'immagine.
  static void paintFills(
    Canvas canvas,
    List<InkFill> fills,
    Rect src,
    Rect dst,
  ) {
    if (fills.isEmpty) return;
    final sx = dst.width / src.width, sy = dst.height / src.height;
    canvas.save();
    canvas.clipRect(dst);
    canvas.translate(dst.left - src.left * sx, dst.top - src.top * sy);
    canvas.scale(sx, sy);
    for (final f in fills) {
      if (!f.bounds.overlaps(src)) continue;
      final cs = f.corners;
      final path = Path()..addPolygon(cs, true);
      canvas.drawPath(path, f.white ? _white : _black);
    }
    canvas.restore();
  }

  factory DocSource.build(
    ui.Image original,
    StripDocument doc, {
    List<InkFill> fills = const [],
  }) {
    if (fills.isEmpty &&
        doc.width == original.width &&
        doc.height == original.height) {
      return DocSource._(original, doc, original, false);
    }
    // nel browser niente copia appiattita: si disegnano i blocchi
    // dell'originale, così ogni pagina occupa la memoria una volta sola
    if (kIsWeb || doc.width > maxFlatSide || doc.height > maxFlatSide) {
      return DocSource._(original, doc, null, false, fills);
    }
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final p = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (final t in doc.tiles()) {
      final s = Rect.fromLTWH(
        t[0].toDouble(),
        t[1].toDouble(),
        t[4].toDouble(),
        t[5].toDouble(),
      );
      final d = Rect.fromLTWH(
        t[2].toDouble(),
        t[3].toDouble(),
        t[4].toDouble(),
        t[5].toDouble(),
      );
      c.drawImageRect(original, s, d, p);
      paintFills(c, fills, s, d);
    }
    final pic = rec.endRecording();
    try {
      final img = pic.toImageSync(doc.width, doc.height);
      return DocSource._(original, doc, img, true);
    } catch (_) {
      return DocSource._(original, doc, null, false, fills);
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
      final s = Rect.fromLTWH(
        t[0].toDouble(),
        t[1].toDouble(),
        t[4].toDouble(),
        t[5].toDouble(),
      );
      canvas.drawImageRect(original, s, d, paint);
      paintFills(canvas, fills, s, d);
    }
  }

  void dispose() {
    if (_ownsFlat) flat?.dispose();
  }
}
