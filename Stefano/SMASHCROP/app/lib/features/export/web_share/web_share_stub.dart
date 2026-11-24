import 'dart:typed_data';

/// Fuori dal browser non serve: l'app salva direttamente in Foto e File.
bool canShareFile(Uint8List bytes, String name, String mime) => false;

Future<bool> shareFile(Uint8List bytes, String name, String mime) async =>
    false;
