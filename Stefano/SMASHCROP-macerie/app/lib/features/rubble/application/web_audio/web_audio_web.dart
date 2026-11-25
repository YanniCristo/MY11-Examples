import 'dart:js_interop';

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

/// Suoni nel browser con Web Audio: il suono è già decodificato in memoria e
/// parte nello stesso istante del pugno. Il lettore audio normale del browser
/// (quello di audioplayers) su iPhone arriva in ritardo di circa 0,15 s.
class WebAudio {
  WebAudio() {
    // Safari sblocca l'audio solo dentro un tocco: ogni tocco lo riattiva
    web.window.addEventListener(
      'pointerdown',
      ((web.Event _) => _unlock()).toJS,
      true.toJS,
    );
  }

  static final WebAudio instance = WebAudio();

  web.AudioContext? _ctx;
  final Map<String, web.AudioBuffer> _buffers = {};
  final Map<String, Future<void>> _loading = {};

  web.AudioContext get _context => _ctx ??= web.AudioContext();

  void _unlock() {
    try {
      final c = _context;
      if (c.state != 'running') c.resume();
    } catch (_) {}
  }

  /// Carica e decodifica un suono (una volta sola).
  Future<void> load(String asset) => _loading[asset] ??= _load(asset);

  Future<void> _load(String asset) async {
    try {
      final data = await rootBundle.load('assets/$asset');
      // copia: decodeAudioData si "prende" il buffer
      final bytes = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final buf = await _context.decodeAudioData(bytes.buffer.toJS).toDart;
      _buffers[asset] = buf;
    } catch (_) {
      _loading.remove(asset);
    }
  }

  /// `true` se il suono è partito; `false` se non era ancora pronto.
  bool play(String asset, {double volume = 1}) {
    final buf = _buffers[asset];
    if (buf == null) {
      load(asset);
      return false;
    }
    try {
      final c = _context;
      if (c.state != 'running') c.resume();
      final src = c.createBufferSource()..buffer = buf;
      final gain = c.createGain();
      gain.gain.value = volume;
      src.connect(gain);
      gain.connect(c.destination);
      src.start();
      return true;
    } catch (_) {
      return false;
    }
  }
}
