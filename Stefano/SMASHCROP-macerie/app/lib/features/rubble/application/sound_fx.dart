import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/skins.dart';

/// Suoni e vibrazione dei colpi.
///
/// Sull'iPhone i suoni seguono il tasto silenzioso (categoria "ambient") e
/// si mescolano alla musica dell'utente senza fermarla. Nel browser partono
/// solo dopo un tocco (regola dei browser): il primo taglio è già un tocco.
class SoundFx {
  SoundFx._();
  static final SoundFx instance = SoundFx._();

  final _rnd = math.Random();
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _ready = false;
  final Map<String, int> _last = {};

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          respectSilence: true,
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
    } catch (_) {}
    for (var i = 0; i < 4; i++) {
      final p = AudioPlayer();
      try {
        await p.setReleaseMode(ReleaseMode.stop);
      } catch (_) {}
      _pool.add(p);
    }
  }

  Future<void> _play(String asset, {double volume = 1}) async {
    try {
      await _init();
      final p = _pool[_next];
      _next = (_next + 1) % _pool.length;
      await p.stop();
      await p.play(AssetSource(asset), volume: volume);
    } catch (e) {
      if (kDebugMode) debugPrint('suono non riprodotto: $e');
    }
  }

  /// Uno dei suoni del personaggio, a caso ma mai lo stesso due volte di fila.
  void hit(SkinDef skin) {
    final n = skin.sounds.length;
    if (n == 0) return;
    var i = _rnd.nextInt(n);
    if (n > 1 && i == _last[skin.id]) i = (i + 1) % n;
    _last[skin.id] = i;
    _play(skin.sounds[i]);
  }

  void gnam() => _play('sounds/gnam_barra.mp3', volume: .8);

  static void punch() => HapticFeedback.mediumImpact();
  static void tick() => HapticFeedback.lightImpact();
}
