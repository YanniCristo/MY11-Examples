import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

/// Formato in cui salvare il risultato, deciso dal file di partenza.
enum OutputFormat { png, jpeg }

/// Un'immagine importata: l'originale decodificato non viene mai modificato.
class LoadedImage {
  LoadedImage({required this.image, required this.format, required this.name});

  final ui.Image image;
  final OutputFormat format;
  final String name;

  int get width => image.width;
  int get height => image.height;
}

class ImageLoadException implements Exception {
  ImageLoadException(this.tooLarge);
  final bool tooLarge;
}

/// Importa un'immagine dalla libreria del dispositivo.
class ImageLoader {
  ImageLoader({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const int maxSide = 16000;
  final ImagePicker _picker;

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
    return LoadedImage(image: img, format: _formatOf(bytes), name: name);
  }

  /// PNG, WebP e GIF possono avere trasparenza: si salvano in PNG.
  /// Tutto il resto (JPEG, HEIC…) si salva in JPEG.
  static OutputFormat _formatOf(Uint8List b) {
    bool starts(List<int> sig, [int at = 0]) {
      if (b.length < at + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[at + i] != sig[i]) return false;
      }
      return true;
    }

    if (starts(const [0x89, 0x50, 0x4E, 0x47])) return OutputFormat.png;
    if (starts(const [0x47, 0x49, 0x46])) return OutputFormat.png;
    if (starts(const [0x52, 0x49, 0x46, 0x46]) &&
        starts(const [0x57, 0x45, 0x42, 0x50], 8)) {
      return OutputFormat.png;
    }
    return OutputFormat.jpeg;
  }
}
