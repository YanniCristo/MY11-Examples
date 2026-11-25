import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import 'blob_store.dart';

/// Copia del file su cui si sta lavorando, per riprendere il lavoro senza
/// doverlo scegliere di nuovo. Resta solo sul dispositivo (nello spazio
/// dell'app, o nella memoria del sito nel browser) e si cancella quando il
/// lavoro salvato sparisce.
///
/// Due posti: "in prova" (il file appena aperto) e "attuale" (quello del
/// lavoro salvato). Un file aperto diventa attuale solo al primo taglio:
/// così aprire un altro file senza toccarlo non fa perdere il lavoro vecchio.
class WorkFileStore {
  WorkFileStore._();
  static final WorkFileStore instance = WorkFileStore._();

  static const _pendingKey = 'work_file_pending';
  static const _currentKey = 'work_file_current';

  /// Oltre questo peso non si tiene la copia (si riprende come prima,
  /// scegliendo di nuovo il file).
  static int get maxBytes => BlobStore.maxBytes;

  final BlobStore _blobs = BlobStore();
  Future<void>? _staging;

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  _Meta? _read(SharedPreferences? p, String key) {
    final raw = p?.getString(key);
    if (raw == null) return null;
    try {
      return _Meta.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Il file è stato appena aperto: se ne fa una copia "in prova".
  void stage(Uint8List bytes, {required String name, required bool isPdf}) {
    if (bytes.length > maxBytes) return;
    _staging = _stage(bytes, name, isPdf).catchError((_) {});
  }

  Future<void> _stage(Uint8List bytes, String name, bool isPdf) async {
    final p = await _prefs();
    if (p == null) return;
    final current = _read(p, _currentKey);
    final slot = current?.slot == 'a' ? 'b' : 'a';
    await p.remove(_pendingKey);
    await _blobs.write(slot, bytes);
    final meta = _Meta(slot, name, bytes.length, isPdf);
    await p.setString(_pendingKey, jsonEncode(meta.toJson()));
  }

  /// Primo taglio sul file aperto: la copia "in prova" diventa quella del
  /// lavoro salvato (e quella del lavoro vecchio si cancella).
  Future<void> promote({
    required String name,
    required int size,
    required bool isPdf,
  }) async {
    try {
      await _staging;
      final p = await _prefs();
      if (p == null) return;
      final pending = _read(p, _pendingKey);
      final current = _read(p, _currentKey);
      if (current != null && current.matches(name, size, isPdf)) return;
      if (pending == null || !pending.matches(name, size, isPdf)) return;
      await p.setString(_currentKey, jsonEncode(pending.toJson()));
      await p.remove(_pendingKey);
      if (current != null && current.slot != pending.slot) {
        await _blobs.delete(current.slot);
      }
    } catch (_) {}
  }

  /// La copia del file del lavoro salvato, se c'è ed è proprio quel file.
  Future<Uint8List?> load({
    required String name,
    required int size,
    required bool isPdf,
  }) async {
    try {
      final p = await _prefs();
      final current = _read(p, _currentKey);
      if (current == null || !current.matches(name, size, isPdf)) return null;
      final bytes = await _blobs.read(current.slot);
      if (bytes == null || bytes.length != size) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Il lavoro salvato non c'è più: via anche la copia del file.
  Future<void> clear() async {
    try {
      final p = await _prefs();
      final current = _read(p, _currentKey);
      if (current == null) return;
      await p?.remove(_currentKey);
      await _blobs.delete(current.slot);
    } catch (_) {}
  }
}

class _Meta {
  _Meta(this.slot, this.name, this.size, this.isPdf);
  final String slot;
  final String name;
  final int size;
  final bool isPdf;

  bool matches(String n, int s, bool pdf) =>
      n == name && s == size && pdf == isPdf;

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'name': name,
    'size': size,
    'pdf': isPdf,
  };

  factory _Meta.fromJson(Map<String, dynamic> m) => _Meta(
    m['slot'] as String,
    m['name'] as String,
    (m['size'] as num).toInt(),
    m['pdf'] as bool,
  );
}
