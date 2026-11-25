import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// File salvati nella memoria del sito (IndexedDB) del browser.
class BlobStore {
  /// Nel browser lo spazio è più stretto.
  static const int maxBytes = 150 << 20;

  static const _db = 'smashcrop_work';
  static const _store = 'files';

  Future<web.IDBDatabase> _open() {
    final c = Completer<web.IDBDatabase>();
    final req = web.window.indexedDB.open(_db, 1);
    req.onupgradeneeded = ((web.Event _) {
      final db = req.result! as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_store)) db.createObjectStore(_store);
    }).toJS;
    req.onsuccess = ((web.Event _) {
      c.complete(req.result! as web.IDBDatabase);
    }).toJS;
    req.onerror = ((web.Event _) => c.completeError('indexedDB')).toJS;
    return c.future;
  }

  Future<JSAny?> _run(
    String mode,
    web.IDBRequest Function(web.IDBObjectStore s) op,
  ) async {
    final db = await _open();
    try {
      final tx = db.transaction(_store.toJS, mode);
      final req = op(tx.objectStore(_store));
      final c = Completer<JSAny?>();
      tx.oncomplete = ((web.Event _) {
        if (!c.isCompleted) c.complete(req.result);
      }).toJS;
      tx.onerror = ((web.Event _) {
        if (!c.isCompleted) c.completeError('indexedDB');
      }).toJS;
      tx.onabort = ((web.Event _) {
        if (!c.isCompleted) c.completeError('indexedDB');
      }).toJS;
      return await c.future;
    } finally {
      db.close();
    }
  }

  Future<void> write(String slot, Uint8List bytes) async {
    await _run('readwrite', (s) => s.put(bytes.toJS, slot.toJS));
  }

  Future<Uint8List?> read(String slot) async {
    final v = await _run('readonly', (s) => s.get(slot.toJS));
    if (v == null || v.isUndefinedOrNull) return null;
    return (v as JSUint8Array).toDart;
  }

  Future<void> delete(String slot) async {
    await _run('readwrite', (s) => s.delete(slot.toJS));
  }
}
