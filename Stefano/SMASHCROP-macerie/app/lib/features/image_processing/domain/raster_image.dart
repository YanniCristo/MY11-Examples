import 'dart:typed_data';

import '../../editor/domain/cut_operation.dart';
import '../../editor/domain/strip_document.dart';

/// Immagine in memoria: pixel RGBA a 8 bit per canale, alpha non
/// premoltiplicato, riga dopo riga.
///
/// Il motore di taglio lavora solo copiando byte: nessun pixel viene
/// ricalcolato, ridimensionato o inventato.
class RasterImage {
  RasterImage(this.width, this.height, this.rgba) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Dimensioni non valide: ${width}x$height');
    }
    if (rgba.length != width * height * 4) {
      throw ArgumentError('Buffer di ${rgba.length} byte per ${width}x$height');
    }
  }

  final int width;
  final int height;
  final Uint8List rgba;

  int get rowBytes => width * 4;

  /// Applica un taglio e restituisce una nuova immagine.
  RasterImage cut(CutOperation op) {
    final len = op.orientation == CutOrientation.horizontal ? height : width;
    if (op.lengthBefore != len || op.start < 0 || op.end > len) {
      throw StateError('$op non è applicabile a ${width}x$height');
    }
    if (op.lengthAfter < 1) throw StateError('Il taglio eliminerebbe tutto');
    return op.orientation == CutOrientation.horizontal
        ? _removeRows(op.start, op.end)
        : _removeCols(op.start, op.end);
  }

  RasterImage _removeRows(int top, int bottom) {
    final newH = height - (bottom - top);
    final out = Uint8List(width * newH * 4);
    final rb = rowBytes;
    out.setRange(0, top * rb, rgba, 0);
    out.setRange(top * rb, newH * rb, rgba, bottom * rb);
    return RasterImage(width, newH, out);
  }

  RasterImage _removeCols(int left, int right) {
    final newW = width - (right - left);
    final out = Uint8List(newW * height * 4);
    final rb = rowBytes;
    final nrb = newW * 4;
    final leftBytes = left * 4;
    final rightBytes = (width - right) * 4;
    for (var y = 0; y < height; y++) {
      final src = y * rb;
      final dst = y * nrb;
      out.setRange(dst, dst + leftBytes, rgba, src);
      out.setRange(
        dst + leftBytes,
        dst + leftBytes + rightBytes,
        rgba,
        src + right * 4,
      );
    }
    return RasterImage(newW, height, out);
  }

  /// Ricostruisce il risultato finale dall'originale e dalle righe e colonne
  /// rimaste. È equivalente ad applicare i tagli uno dopo l'altro.
  static RasterImage compose(RasterImage original, StripDocument doc) {
    if (original.width != doc.originalWidth ||
        original.height != doc.originalHeight) {
      throw ArgumentError('Originale e documento non corrispondono');
    }
    return composeTiles(original, doc.width, doc.height, doc.tiles());
  }

  /// Come [compose], ma a partire dall'elenco dei blocchi
  /// `[srcX, srcY, dstX, dstY, w, h]` (utile per lavorare in un isolate).
  static RasterImage composeTiles(
    RasterImage original,
    int width,
    int height,
    List<List<int>> tiles,
  ) {
    final out = Uint8List(width * height * 4);
    final srcRb = original.rowBytes;
    final dstRb = width * 4;
    for (final t in tiles) {
      final sx = t[0], sy = t[1], dx = t[2], dy = t[3], w = t[4], h = t[5];
      for (var i = 0; i < h; i++) {
        final s = (sy + i) * srcRb + sx * 4;
        final d = (dy + i) * dstRb + dx * 4;
        out.setRange(d, d + w * 4, original.rgba, s);
      }
    }
    return RasterImage(width, height, out);
  }

  /// Pixel come intero 0xRRGGBBAA (utile nei test).
  int pixel(int x, int y) {
    final i = (y * width + x) * 4;
    return (rgba[i] << 24) |
        (rgba[i + 1] << 16) |
        (rgba[i + 2] << 8) |
        rgba[i + 3];
  }
}
