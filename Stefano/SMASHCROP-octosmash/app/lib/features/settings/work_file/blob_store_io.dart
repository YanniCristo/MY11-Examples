import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// File salvati nella cartella privata dell'app (non visibile all'utente,
/// esclusa dalle cartelle condivise).
class BlobStore {
  static const int maxBytes = 300 << 20;

  Future<File> _file(String slot) async {
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/work_file',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/$slot.bin');
  }

  Future<void> write(String slot, Uint8List bytes) async {
    await (await _file(slot)).writeAsBytes(bytes, flush: true);
  }

  Future<Uint8List?> read(String slot) async {
    final f = await _file(slot);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }

  Future<void> delete(String slot) async {
    final f = await _file(slot);
    if (await f.exists()) await f.delete();
  }
}
