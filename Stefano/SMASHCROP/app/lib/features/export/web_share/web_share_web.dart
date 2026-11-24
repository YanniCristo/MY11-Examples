import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

web.ShareData _data(Uint8List bytes, String name, String mime) {
  final file = web.File(
    <web.BlobPart>[bytes.toJS].toJS,
    name,
    web.FilePropertyBag(type: mime),
  );
  return web.ShareData(files: <web.File>[file].toJS);
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
