import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../image_processing/domain/raster_image.dart';
import '../image_processing/services/image_loader.dart' show OutputFormat;

/// Lavoro di esportazione di un'immagine, eseguito in un isolate.
class ImageEncodeJob {
  ImageEncodeJob({
    required this.format,
    required this.srcW,
    required this.srcH,
    required this.outW,
    required this.outH,
    required this.tiles,
    this.original,
    this.rgba,
    this.flattenOnWhite = false,
  });

  /// Formato di uscita: lo stesso del file caricato.
  final OutputFormat format;
  final int srcW, srcH, outW, outH;
  final List<List<int>> tiles;

  /// File originale: da qui si leggono i pixel esatti e il profilo colore.
  final Uint8List? original;

  /// Pixel già decodificati dal sistema, usati solo se il file originale non
  /// si può leggere qui (per esempio HEIC).
  final Uint8List? rgba;

  /// Le parti trasparenti diventano bianche (per il JPEG dentro un PDF).
  final bool flattenOnWhite;
}

/// Qualità JPEG massima e colore pieno (4:4:4, nessun sottocampionamento):
/// la differenza rispetto all'originale resta sotto la soglia visibile.
const int kJpegQuality = 100;

/// Restituisce il file finale, oppure `null` se servono i pixel del sistema
/// (formato non leggibile qui o dimensioni non coerenti).
Uint8List? encodeImageJob(ImageEncodeJob j) {
  img.IccProfile? icc;
  RasterImage? source;

  final original = j.original;
  if (original != null) {
    try {
      final decoded = img.decodeImage(original);
      if (decoded != null) {
        icc = decoded.iccProfile;
        // stesso orientamento che mostra il telefono (EXIF applicato)
        final baked = img.bakeOrientation(decoded);
        if (baked.width == j.srcW && baked.height == j.srcH) {
          final eight =
              !baked.hasPalette &&
                  baked.format == img.Format.uint8 &&
                  baked.numChannels == 4
              ? baked
              : baked.convert(
                  format: img.Format.uint8,
                  numChannels: 4,
                  alpha: 255,
                );
          source = RasterImage(
            j.srcW,
            j.srcH,
            Uint8List.fromList(eight.getBytes(order: img.ChannelOrder.rgba)),
          );
        }
      }
    } catch (_) {
      source = null;
    }
  }
  if (source == null) {
    final rgba = j.rgba;
    if (rgba == null) return null;
    source = RasterImage(j.srcW, j.srcH, rgba);
  }

  final out = RasterImage.composeTiles(source, j.outW, j.outH, j.tiles);
  if (j.flattenOnWhite) {
    final px = out.rgba;
    for (var p = 0; p < px.length; p += 4) {
      final a = px[p + 3];
      if (a == 255) continue;
      for (var k = 0; k < 3; k++) {
        px[p + k] = (px[p + k] * a + 255 * (255 - a)) ~/ 255;
      }
      px[p + 3] = 255;
    }
  }
  final image = img.Image.fromBytes(
    width: out.width,
    height: out.height,
    bytes: out.rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  // il profilo colore resta (es. Display P3 degli iPhone); i dati EXIF no:
  // l'orientamento è già applicato, la miniatura mostrerebbe l'immagine
  // prima del taglio e la posizione GPS non deve partire con il file
  image.iccProfile = icc;
  return encodeAs(j.format, image);
}

/// Codifica nel formato richiesto. Tutti senza perdita tranne il JPEG, che
/// per sua natura ricomprime: qualità 100 e colore pieno 4:4:4.
Uint8List encodeAs(OutputFormat f, img.Image image) => switch (f) {
  OutputFormat.png => img.encodePng(image, level: 6),
  OutputFormat.webp => img.encodeWebP(image), // lossless
  OutputFormat.gif => img.encodeGif(_exactPalette(image) ?? image),
  OutputFormat.bmp => img.encodeBmp(image),
  OutputFormat.tiff => img.encodeTiff(image),
  OutputFormat.jpeg => img.encodeJpg(
    image,
    quality: kJpegQuality,
    chroma: img.JpegChroma.yuv444,
  ),
};

/// Una GIF ha al massimo 256 colori; tagliare non ne aggiunge, quindi si
/// ricostruisce la tavolozza esatta senza riquantizzare né retinare.
img.Image? _exactPalette(img.Image src) {
  final index = <int, int>{};
  final w = src.width, h = src.height;
  final rgba = src.getBytes(order: img.ChannelOrder.rgba);
  final idx = Uint8List(w * h);
  for (var i = 0, p = 0; i < idx.length; i++, p += 4) {
    // i pixel trasparenti diventano un solo colore trasparente
    final a = rgba[p + 3];
    final key = a < 128
        ? -1
        : (rgba[p] << 16) | (rgba[p + 1] << 8) | rgba[p + 2];
    var k = index[key];
    if (k == null) {
      if (index.length == 256) return null;
      k = index[key] = index.length;
    }
    idx[i] = k;
  }
  final pal = img.PaletteUint8(index.length, 4);
  index.forEach((key, k) {
    if (key < 0) {
      pal.setRgba(k, 0, 0, 0, 0);
    } else {
      pal.setRgba(k, (key >> 16) & 255, (key >> 8) & 255, key & 255, 255);
    }
  });
  final out = img.Image(width: w, height: h, numChannels: 1, palette: pal);
  out.getBytes().setAll(0, idx);
  return out;
}
