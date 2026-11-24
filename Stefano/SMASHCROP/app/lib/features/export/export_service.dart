import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';

import '../editor/domain/strip_document.dart';
import '../image_processing/domain/raster_image.dart';
import '../image_processing/services/image_loader.dart';

enum SaveOutcome { saved, denied, unavailable, failed }

class ExportedFile {
  ExportedFile(this.bytes, this.format, this.fileName);
  final Uint8List bytes;
  final OutputFormat format;
  final String fileName;
  String get baseName => fileName.substring(0, fileName.lastIndexOf('.'));
  String get mimeType =>
      format == OutputFormat.png ? 'image/png' : 'image/jpeg';
}

/// Genera il file finale a piena risoluzione dall'originale e dai tagli,
/// poi lo salva nelle Foto o lo passa al sistema di condivisione.
class ExportService {
  const ExportService();

  Future<ExportedFile> build(LoadedImage source, StripDocument doc) async {
    final data = await source.image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    if (data == null) throw StateError('Pixel non disponibili');
    final job = _EncodeJob(
      rgba: data.buffer.asUint8List(),
      srcW: source.width,
      srcH: source.height,
      outW: doc.width,
      outH: doc.height,
      tiles: doc.tiles(),
      png: source.format == OutputFormat.png,
    );
    final bytes = await compute(_encode, job);
    final stamp = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final name =
        'SmashCrop_${stamp.year}${two(stamp.month)}${two(stamp.day)}_'
        '${two(stamp.hour)}${two(stamp.minute)}${two(stamp.second)}';
    return ExportedFile(
      bytes,
      source.format,
      '$name.${source.format == OutputFormat.png ? 'png' : 'jpg'}',
    );
  }

  Future<SaveOutcome> saveToPhotos(ExportedFile file) async {
    if (kIsWeb) return SaveOutcome.unavailable;
    try {
      if (!await Gal.hasPermission()) {
        if (!await Gal.requestPermission()) return SaveOutcome.denied;
      }
      await Gal.putImageBytes(file.bytes, name: file.baseName);
      return SaveOutcome.saved;
    } on GalException catch (e) {
      return e.type == GalExceptionType.permissionDenied
          ? SaveOutcome.denied
          : SaveOutcome.failed;
    } catch (_) {
      return SaveOutcome.failed;
    }
  }

  /// `true` se il foglio di condivisione si è aperto correttamente.
  Future<bool> share(ExportedFile file, {ui.Rect? origin}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              file.bytes,
              mimeType: file.mimeType,
              name: file.fileName,
            ),
          ],
          fileNameOverrides: [file.fileName],
          sharePositionOrigin: origin,
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }
}

class _EncodeJob {
  _EncodeJob({
    required this.rgba,
    required this.srcW,
    required this.srcH,
    required this.outW,
    required this.outH,
    required this.tiles,
    required this.png,
  });
  final Uint8List rgba;
  final int srcW, srcH, outW, outH;
  final List<List<int>> tiles;
  final bool png;
}

Uint8List _encode(_EncodeJob j) {
  final original = RasterImage(j.srcW, j.srcH, j.rgba);
  final out = RasterImage.composeTiles(original, j.outW, j.outH, j.tiles);
  final image = img.Image.fromBytes(
    width: out.width,
    height: out.height,
    bytes: out.rgba.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  // JPEG solo per sorgenti senza trasparenza; qualità alta per non degradare.
  return j.png
      ? img.encodePng(image, level: 6)
      : img.encodeJpg(image, quality: 95);
}
