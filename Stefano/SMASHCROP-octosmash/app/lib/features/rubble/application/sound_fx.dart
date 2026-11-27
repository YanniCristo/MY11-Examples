import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/skins.dart';
import 'web_audio/web_audio.dart';

/// Suoni e vibrazione dei colpi.
///
/// I suoni partono anche col tasto silenzioso attivo, al volume impostato
/// (scelta di Stefano), e si mescolano alla musica dell'utente senza
/// fermarla. Nel browser partono
/// solo dopo un tocco (regola dei browser): il primo taglio è già un tocco.
class SoundFx {
  SoundFx._();
  static final SoundFx instance = SoundFx._();

  final _rnd = math.Random();
  bool _ready = false;
  final Map<String, int> _last = {};

  /// Un lettore già caricato per ogni suono: al colpo si fa solo "play",
  /// senza scaricare né decodificare niente (altrimenti il suono arriva in
  /// ritardo, soprattutto nel browser).
  final Map<String, AudioPlayer> _players = {};

  static const _pling = 'sounds/pling_barra.mp3';

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          // suona anche col tasto silenzioso, al volume impostato
          respectSilence: false,
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
    } catch (_) {}
  }

  Future<AudioPlayer?> _player(String asset) async {
    final have = _players[asset];
    if (have != null) return have;
    try {
      await _init();
      final p = AudioPlayer();
      _players[asset] = p;
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setSource(AssetSource(asset));
      return p;
    } catch (e) {
      if (kDebugMode) debugPrint('suono non caricato: $e');
      return null;
    }
  }

  /// Carica in anticipo i suoni del personaggio in uso (all'apertura
  /// dell'editor e quando si cambia skin).
  Future<void> prepare(SkinDef skin) async {
    for (final a in [...skin.sounds, _pling]) {
      kIsWeb ? await WebAudio.instance.load(a) : await _player(a);
    }
  }

  Future<void> _play(String asset, {double volume = 1}) async {
    // nel browser Web Audio: parte subito, senza il ritardo del lettore
    if (kIsWeb && WebAudio.instance.play(asset, volume: volume)) return;
    try {
      final p = await _player(asset);
      if (p == null) return;
      await p.setVolume(volume);
      // stop riporta all'inizio tenendo il suono caricato
      await p.stop();
      await p.resume();
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

  // --- OctoSmash ------------------------------------------------------------

  /// Suoni dello spruzzo per ogni OctoSmash (4 varianti ciascuno, come per
  /// SMASH). Chi non li ha ancora resta muto.
  static const Map<String, List<String>> _octo = {
    'bianco': [
      'sounds/octo/octo_bianco_1.mp3',
      'sounds/octo/octo_bianco_2.mp3',
      'sounds/octo/octo_bianco_3.mp3',
      'sounds/octo/octo_bianco_4.mp3',
    ],
    'nero': [
      'sounds/octo/octo_nero_1.mp3',
      'sounds/octo/octo_nero_2.mp3',
      'sounds/octo/octo_nero_3.mp3',
      'sounds/octo/octo_nero_4.mp3',
    ],
    'pipetta': [
      'sounds/octo/octo_pipetta_1.mp3',
      'sounds/octo/octo_pipetta_2.mp3',
      'sounds/octo/octo_pipetta_3.mp3',
      'sounds/octo/octo_pipetta_4.mp3',
    ],
    'multicolor': [
      'sounds/octo/octo_multicolor_1.mp3',
      'sounds/octo/octo_multicolor_2.mp3',
      'sounds/octo/octo_multicolor_3.mp3',
      'sounds/octo/octo_multicolor_4.mp3',
    ],
    'fusione': [
      'sounds/octo/octo_fusione_1.mp3',
      'sounds/octo/octo_fusione_2.mp3',
      'sounds/octo/octo_fusione_3.mp3',
      'sounds/octo/octo_fusione_4.mp3',
    ],
    'stampa': [
      'sounds/octo/octo_stampa_1.mp3',
      'sounds/octo/octo_stampa_2.mp3',
      'sounds/octo/octo_stampa_3.mp3',
      'sounds/octo/octo_stampa_4.mp3',
    ],
    'abisso': [
      'sounds/octo/octo_abisso_1.mp3',
      'sounds/octo/octo_abisso_2.mp3',
      'sounds/octo/octo_abisso_3.mp3',
      'sounds/octo/octo_abisso_4.mp3',
    ],
    'diluvio': [
      'sounds/octo/octo_diluvio_1.mp3',
      'sounds/octo/octo_diluvio_2.mp3',
      'sounds/octo/octo_diluvio_3.mp3',
      'sounds/octo/octo_diluvio_4.mp3',
    ],
    'imperatore': [
      'sounds/octo/octo_imperatore_1.mp3',
      'sounds/octo/octo_imperatore_2.mp3',
      'sounds/octo/octo_imperatore_3.mp3',
      'sounds/octo/octo_imperatore_4.mp3',
    ],
  };

  static const List<String> _fusionScene = [
    'sounds/octo/scena_fusione_1.mp3',
    'sounds/octo/scena_fusione_2.mp3',
    'sounds/octo/scena_fusione_3.mp3',
    'sounds/octo/scena_fusione_4.mp3',
  ];

  Future<void> _load(List<String> assets) => Future.wait([
    for (final a in assets)
      kIsWeb ? WebAudio.instance.load(a) : _player(a).then((_) {}),
  ]);

  /// Come [_play], ma se il suono non è ancora caricato lo aspetta (fino a
  /// poco più di un secondo: dopo sarebbe fuori tempo) invece di restare muto.
  Future<void> _playReady(String asset) async {
    if (kIsWeb) {
      if (WebAudio.instance.play(asset)) return;
      final t = DateTime.now();
      await WebAudio.instance.load(asset);
      if (DateTime.now().difference(t).inMilliseconds < 1200) {
        WebAudio.instance.play(asset);
      }
      return;
    }
    await _play(asset);
  }

  void _pick(String key, List<String> assets) {
    final n = assets.length;
    if (n == 0) return;
    var i = _rnd.nextInt(n);
    if (n > 1 && i == _last[key]) i = (i + 1) % n;
    _last[key] = i;
    _playReady(assets[i]);
  }

  /// Carica in anticipo i suoni di un OctoSmash (solo i suoi 4: tenerli
  /// tutti in memoria su iPhone pesa).
  Future<void> prepareOctoLine(String line) => _load(_octo[line] ?? const []);

  /// Carica in anticipo il sottofondo della scena della fusione.
  Future<void> prepareFusionScene() => _load(_fusionScene);

  /// Lo spruzzo di un OctoSmash ('bianco', 'stampa'...).
  void octo(String line) => _pick('octo:$line', _octo[line] ?? const []);

  /// La scena dei 4 che si fondono.
  void fusionScene() => _pick('scena', _fusionScene);

  /// I pezzi arrivano alla barra: un "pling" chiaro e breve.
  void pling() => _play(_pling, volume: .55);

  static void punch() => HapticFeedback.mediumImpact();
  static void tick() => HapticFeedback.lightImpact();
}
