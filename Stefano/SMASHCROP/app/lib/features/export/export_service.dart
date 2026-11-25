import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../editor/domain/strip_document.dart';
import '../image_processing/services/image_loader.dart';
import 'image_encoder.dart';

enum SaveOutcome { saved, denied, unavailable, failed }

class ExportedFile {
  ExportedFile(this.bytes, this.format, this.fileName);
  final Uint8List bytes;
  final OutputFormat format;
  final String fileName;
  String get baseName => fileName.substring(0, fileName.lastIndexOf('.'));
  String get mimeType => format.mimeType;
}

/// Genera il file finale a piena risoluzione dall'originale e dai tagli,
/// poi lo salva nelle Foto o lo passa al sistema di condivisione.
class ExportService {
  const ExportService();

  Future<ExportedFile> build(LoadedImage source, StripDocument doc) =>
      buildFile(source.file, doc, pixels: () async => source.image);

  /// Il file finale di un'immagine. [pixels] dà i pixel decodificati dal
  /// sistema: si usano solo se il file non si legge qui (HEIC).
  /// [format] cambia il formato d'uscita (JPEG per il PDF).
  Future<ExportedFile> buildFile(
    ImageFile source,
    StripDocument doc, {
    required Future<ui.Image> Function() pixels,
    OutputFormat? format,
    bool flattenOnWhite = false,
    String? baseName,
  }) async {
    final out = format ?? source.format;
    ImageEncodeJob job({Uint8List? rgba}) => ImageEncodeJob(
      format: out,
      srcW: source.width,
      srcH: source.height,
      outW: doc.width,
      outH: doc.height,
      tiles: doc.tiles(),
      original: rgba == null ? source.bytes : null,
      rgba: rgba,
      flattenOnWhite: flattenOnWhite,
    );
    // prima dal file originale (pixel e colori esatti), poi, se il formato
    // non si legge qui (HEIC), dai pixel decodificati dal sistema
    var bytes = source.bytes == null
        ? null
        : await compute(encodeImageJob, job());
    if (bytes == null) {
      final image = await pixels();
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (data == null) throw StateError('Pixel non disponibili');
      bytes = await compute(
        encodeImageJob,
        job(rgba: data.buffer.asUint8List()),
      );
    }
    if (bytes == null) throw StateError('Esportazione non riuscita');
    final name = baseName ?? baseFileName();
    return ExportedFile(bytes, out, '$name.${out.extension}');
  }

  /// Nome file con data e ora, es. SmashCrop_20261124_212300.
  static String baseFileName() {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'SmashCrop_${t.year}${two(t.month)}${two(t.day)}_${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  /// Nel browser "Salva" scarica il file (oppure, dove il browser lo
  /// permette, apre la finestra per scegliere dove metterlo).
  Future<bool> download(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
      );
      return true;
    } catch (_) {
      return false;
    }
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

  /// Salva più immagini nelle Foto: restituisce quante sono andate.
  Future<(int, SaveOutcome)> saveAllToPhotos(List<ExportedFile> files) async {
    var n = 0;
    var last = SaveOutcome.saved;
    for (final f in files) {
      last = await saveToPhotos(f);
      if (last != SaveOutcome.saved) break;
      n++;
    }
    return (n, last);
  }

  /// `true` se il foglio di condivisione si è aperto correttamente.
  Future<bool> share(ExportedFile file, {ui.Rect? origin}) =>
      shareBytes(file.bytes, file.mimeType, file.fileName, origin: origin);

  Future<bool> shareAll(List<ExportedFile> files, {ui.Rect? origin}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            for (final f in files)
              XFile.fromData(f.bytes, mimeType: f.mimeType, name: f.fileName),
          ],
          fileNameOverrides: [for (final f in files) f.fileName],
          sharePositionOrigin: origin,
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }

  Future<bool> shareBytes(
    Uint8List bytes,
    String mimeType,
    String fileName, {
    ui.Rect? origin,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: origin,
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }
}
