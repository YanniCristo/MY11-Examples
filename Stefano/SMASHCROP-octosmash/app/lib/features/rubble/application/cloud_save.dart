import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Salvataggio automatico nell'account del telefono, senza login:
/// iCloud (spazio chiave-valore) su iPhone, Google Block Store su Android.
/// Sul web e dove non è disponibile non fa nulla: resta il codice di recupero.
class CloudSave {
  CloudSave._();

  static const _channel = MethodChannel('smashcrop/cloud');
  static const _key = 'smash_rubble_v1';

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Ultima copia salvata nell'account, o `null`.
  static Future<String?> read() async {
    if (!supported) return null;
    try {
      return await _channel
          .invokeMethod<String>('read', {'key': _key})
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  static Timer? _pending;
  static String? _last;

  /// Salva (con un attimo di ritardo, così tanti tagli di fila fanno una
  /// sola scrittura).
  static void write(String value) {
    if (!supported || value == _last) return;
    _pending?.cancel();
    _pending = Timer(const Duration(seconds: 2), () async {
      try {
        await _channel.invokeMethod('write', {'key': _key, 'value': value});
        _last = value;
      } catch (_) {}
    });
  }

  /// Chiamata quando un altro dispositivo aggiorna la copia (solo iCloud).
  static void onChanged(void Function(String value) f) {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed' && call.arguments is String) {
        f(call.arguments as String);
      }
    });
  }
}
