import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

web.File _file(Uint8List bytes, String name, String mime) => web.File(
  <web.BlobPart>[bytes.toJS].toJS,
  name,
  web.FilePropertyBag(type: mime),
);

web.ShareData _data(Uint8List bytes, String name, String mime) =>
    _dataAll([(bytes, name, mime)]);

web.ShareData _dataAll(List<(Uint8List, String, String)> files) =>
    web.ShareData(
      files: <web.File>[for (final f in files) _file(f.$1, f.$2, f.$3)].toJS,
    );

/// Come [canShareFile], per più file insieme.
bool canShareFiles(List<(Uint8List, String, String)> files) {
  try {
    return web.window.navigator.canShare(_dataAll(files));
  } catch (_) {
    return false;
  }
}

/// Come [shareFile], per più file insieme.
Future<bool> shareFiles(List<(Uint8List, String, String)> files) async {
  try {
    await web.window.navigator.share(_dataAll(files)).toDart;
    return true;
  } catch (_) {
    return false;
  }
}

/// Vero se il browser può passare questo file al menu di condivisione del
/// telefono (Safari e Chrome su iPhone e Android).
bool canShareFile(Uint8List bytes, String name, String mime) {
  try {
    return web.window.navigator.canShare(_data(bytes, name, mime));
  } catch (_) {
    return false;
  }
}

/// Apre il menu di condivisione del telefono con il file. Da lì "Salva
/// immagine" lo mette nelle Foto e "Salva su File" nei File.
/// Va chiamato direttamente da un tocco dell'utente.
Future<bool> shareFile(Uint8List bytes, String name, String mime) async {
  try {
    await web.window.navigator.share(_data(bytes, name, mime)).toDart;
    return true;
  } catch (_) {
    // annullato dall'utente o non consentito
    return false;
  }
}
