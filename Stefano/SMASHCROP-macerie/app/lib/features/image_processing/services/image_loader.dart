import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

/// Formato in cui salvare il risultato, deciso dal file di partenza.
/// Formato del file salvato: lo stesso del file caricato.
/// Unica eccezione HEIC/HEIF (foto iPhone): nessun codificatore disponibile
/// qui, si salva in JPEG alla qualità massima.
enum OutputFormat {
  png('png', 'image/png'),
  jpeg('jpg', 'image/jpeg'),
  webp('webp', 'image/webp'),
  gif('gif', 'image/gif'),
  bmp('bmp', 'image/bmp'),
  tiff('tif', 'image/tiff');

  const OutputFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

/// Un'immagine importata: l'originale decodificato non viene mai modificato.
class LoadedImage {
  LoadedImage({
    required this.image,
    required this.format,
    required this.name,
    this.bytes,
  });

  final ui.Image image;

  /// Il file originale così com'è: l'esportazione riparte da qui per avere
  /// esattamente i pixel e il profilo colore dell'originale.
  final Uint8List? bytes;
  final OutputFormat format;
  final String name;

  int get width => image.width;
  int get height => image.height;

  ImageFile get file => ImageFile(
    bytes: bytes,
    name: name,
    format: format,
    width: width,
    height: height,
  );
}

/// Un'immagine di un gruppo: si tiene solo il file (leggero); i pixel si
/// decodificano quando la sua pagina serve e si liberano quando non serve
/// più, come per le pagine dei PDF.
class ImageFile {
  const ImageFile({
    required this.bytes,
    required this.name,
    required this.format,
    required this.width,
    required this.height,
  });

  final Uint8List? bytes;
  final String name;
  final OutputFormat format;
  final int width;
  final int height;
}

/// Le immagini scelte, nell'ordine di scelta. [decoded] ha le prime già
/// pronte (le altre sono `null` e si decodificano al bisogno).
class PickedImages {
  PickedImages(this.files, this.decoded);
  final List<ImageFile> files;
  final List<ui.Image?> decoded;

  int get length => files.length;
  int get totalBytes => files.fold(0, (s, f) => s + (f.bytes?.length ?? 0));

  factory PickedImages.single(LoadedImage img) =>
      PickedImages([img.file], [img.image]);
}

class ImageLoadException implements Exception {
  ImageLoadException(this.tooLarge);
  final bool tooLarge;
}

/// Importa un'immagine dalla libreria del dispositivo.
class ImageLoader {
  ImageLoader({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const int maxSide = 16000;

  /// Massimo di immagini in un documento.
  static const int maxImages = 50;

  /// Immagini decodificate subito: la prima e la successiva.
  static const int decodedAhead = 2;
  final ImagePicker _picker;

  /// Sceglie una o più immagini. `null` se l'utente annulla.
  /// [confirmSize] riceve il peso totale prima di leggerle: se risponde
  /// `false` l'apertura si annulla. [onTruncated] avvisa se ne sono state
  /// scelte più del massimo.
  /// [max] limita quante se ne possono scegliere (per le aggiunte).
  Future<PickedImages?> pickMany({
    Future<bool> Function(int bytes)? confirmSize,
    void Function(int max)? onTruncated,
    int max = maxImages,
  }) async {
    // con limit 1 alcuni sistemi rifiutano la scelta multipla
    var files = await _picker.pickMultiImage(
      requestFullMetadata: false,
      limit: max >= 2 ? max : null,
    );
    if (files.isEmpty) return null;
    if (files.length > max) {
      files = files.sublist(0, max);
      onTruncated?.call(maxImages);
    }
    if (confirmSize != null) {
      var total = 0;
      for (final f in files) {
        total += await f.length();
      }
      if (!await confirmSize(total)) return null;
    }
    final out = <ImageFile>[];
    final decoded = <ui.Image?>[];
    try {
      for (final f in files) {
        final loaded = await decode(await f.readAsBytes(), f.name);
        out.add(loaded.file);
        if (decoded.length < decodedAhead) {
          decoded.add(loaded.image);
        } else {
          // servivano solo le misure: i pixel si rifanno quando servono
          loaded.image.dispose();
          decoded.add(null);
        }
      }
    } catch (_) {
      for (final d in decoded) {
        d?.dispose();
      }
      rethrow;
    }
    return PickedImages(out, decoded);
  }

  /// `null` se l'utente annulla la scelta.
  Future<LoadedImage?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return decode(bytes, file.name);
  }

  /// Decodifica con il decoder del sistema (gestisce anche HEIC su iPhone
  /// e l'orientamento EXIF delle foto).
  static Future<LoadedImage> decode(Uint8List bytes, String name) async {
    final ui.Codec codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
    } catch (_) {
      throw ImageLoadException(false);
    }
    final frame = await codec.getNextFrame();
    codec.dispose();
    final img = frame.image;
    if (img.width > maxSide || img.height > maxSide) {
      img.dispose();
      throw ImageLoadException(true);
    }
    return LoadedImage(
      image: img,
      format: _formatOf(bytes),
      name: name,
      bytes: bytes,
    );
  }

  /// Riconosce il formato dal contenuto del file, non dal nome.
  static OutputFormat _formatOf(Uint8List b) {
    bool starts(List<int> sig, [int at = 0]) {
      if (b.length < at + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[at + i] != sig[i]) return false;
      }
      return true;
    }

    if (starts(const [0x89, 0x50, 0x4E, 0x47])) return OutputFormat.png;
    if (starts(const [0x47, 0x49, 0x46])) return OutputFormat.gif;
    if (starts(const [0x52, 0x49, 0x46, 0x46]) &&
        starts(const [0x57, 0x45, 0x42, 0x50], 8)) {
      return OutputFormat.webp;
    }
    if (starts(const [0x42, 0x4D])) return OutputFormat.bmp;
    if (starts(const [0x49, 0x49, 0x2A, 0x00]) ||
        starts(const [0x4D, 0x4D, 0x00, 0x2A])) {
      return OutputFormat.tiff;
    }
    return OutputFormat.jpeg;
  }
}
