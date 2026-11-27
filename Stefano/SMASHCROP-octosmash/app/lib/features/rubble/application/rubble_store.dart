import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/rubble_math.dart';
import '../domain/skins.dart';
import 'cloud_save.dart';

/// Cosa è successo aggiungendo macerie.
class RubbleGain {
  RubbleGain(this.kg, this.evolutions, this.milestones);
  final double kg;
  final List<SkinDef> evolutions;
  final List<String> milestones;
}

/// Il contatore delle macerie e la Collezione, salvati sul dispositivo.
///
/// Regola d'oro: il contatore non scende mai. Annullare un taglio non
/// toglie macerie, e da un codice di recupero si tiene il valore più alto.
class RubbleStore extends ChangeNotifier {
  RubbleStore._(this._prefs);

  static const _key = 'rubble_v1';
  final SharedPreferences? _prefs;

  /// Totale in grammi (intero: niente errori di arrotondamento).
  int grams = 0;

  /// OctoSmash: millilitri d'inchiostro spruzzati, nero (linea Bianca) e
  /// bianco (linea Nera). Contatori separati dalle macerie.
  int inkBlackMl = 0;
  int inkWhiteMl = 0;

  /// OctoSmash scelto nella Collezione: 'squadra' = i 4 di base, ognuno col
  /// suo tasto; altrimenti un'evoluzione che fa tutto lei.
  String octoSkin = 'squadra';

  /// Colori presi con la pipetta: gli ultimi (il primo è il più recente) e
  /// quelli fissati con la puntina, che non scivolano via.
  final List<int> octoRecent = [];
  final List<int> octoPinned = [];
  static const maxRecent = 6, maxPinned = 6;

  /// Un colore preso con la pipetta: va in testa ai recenti (senza doppioni).
  void addPickedColor(int c) {
    if (octoPinned.contains(c)) return;
    octoRecent
      ..remove(c)
      ..insert(0, c);
    if (octoRecent.length > maxRecent) octoRecent.removeLast();
    _save();
    notifyListeners();
  }

  /// Fissa o toglie la puntina a un colore. `false` se i fissati sono pieni.
  bool togglePin(int c) {
    if (octoPinned.remove(c)) {
      octoRecent.insert(0, c);
      if (octoRecent.length > maxRecent) octoRecent.removeLast();
    } else {
      if (octoPinned.length >= maxPinned) return false;
      octoRecent.remove(c);
      octoPinned.add(c);
    }
    _save();
    notifyListeners();
    return true;
  }

  /// Il popup "Novità: OctoSmash" è già stato visto.
  bool octoNewsSeen = false;

  void markOctoNewsSeen() {
    if (octoNewsSeen) return;
    octoNewsSeen = true;
    _save();
  }

  /// La scena della fusione (i 4 che si uniscono) è già stata vista.
  bool fusionSeen = false;

  void markFusionSeen() {
    if (fusionSeen) return;
    fusionSeen = true;
    _save();
  }

  void chooseOcto(String id) {
    if (id == octoSkin) return;
    octoSkin = id;
    _save();
    notifyListeners();
  }

  final Set<String> unlocked = {'smash'};

  /// Skin già viste nella Collezione (le altre sbloccate hanno il pallino).
  final Set<String> seen = {'smash'};
  final Set<String> milestonesDone = {};
  String skinId = 'smash';
  bool sound = true;
  bool haptics = true;

  /// Acquisto a vita ("SmashCrop a vita", vedi features/premium).
  bool lifetime = false;
  bool firstEvolutionDone = false;
  bool collectionHintShown = false;
  bool sleepToastShown = false;
  bool recoveryOffered = false;

  /// L'invito a "SmashCrop a vita" dopo il primo salvataggio è già comparso.
  bool lifetimeOffered = false;

  /// Promemoria di SMASH accesi (interruttore nel menu) e permesso già chiesto.
  bool notify = true;
  bool notifyAsked = false;

  /// Ultimo guadagno (per il "+0,30 kg" sul contatore) e suo contatore.
  double lastGainKg = 0;
  int gainTick = 0;

  /// Il contatore dell'app, caricato all'avvio.
  static late RubbleStore instance;

  static Future<RubbleStore> load() async {
    SharedPreferences? p;
    try {
      p = await SharedPreferences.getInstance();
    } catch (_) {}
    final s = RubbleStore._(p);
    s._read(p?.getString(_key));
    s._cloud = CloudSave.supported;
    // la copia nell'account si legge in sottofondo: l'avvio non aspetta
    if (s._cloud) {
      CloudSave.onChanged(s.mergeFrom);
      unawaited(
        CloudSave.read().then((raw) {
          if (raw != null) s.mergeFrom(raw);
          CloudSave.write(s.encode());
        }),
      );
    }
    return s;
  }

  bool _cloud = false;

  @visibleForTesting
  factory RubbleStore.memory() => RubbleStore._(null);

  double get kg => grams / 1000;
  SkinDef get skin => skinById(skinId);
  SkinDef? get nextEvolution => RubbleMath.next(kg);
  double get progress => RubbleMath.progress(kg);
  bool isUnlocked(SkinDef s) =>
      unlocked.contains(s.id) || (s.unlock == Unlock.lifetime && lifetime);
  bool get hasNew => unlocked.any((id) => !seen.contains(id));

  /// Aggiunge le macerie di un taglio fatto con SMASH acceso.
  RubbleGain add(double kgGain) {
    final before = kg;
    grams += (kgGain * 1000).round();
    lastGainKg = kgGain;
    gainTick++;
    final evo = RubbleMath.crossed(before, kg);
    for (final e in evo) {
      unlocked.add(e.id);
    }
    // la nuova skin si indossa da sola: fa parte della festa
    if (evo.isNotEmpty) skinId = evo.last.id;
    final ms = [
      for (final m in RubbleMath.milestones(before, kg))
        if (milestonesDone.add(m)) m,
    ];
    _save();
    notifyListeners();
    return RubbleGain(kgGain, evo, ms);
  }

  void choose(SkinDef s) {
    if (!isUnlocked(s) || s.id == skinId) return;
    skinId = s.id;
    _save();
    notifyListeners();
  }

  void markSeen() {
    if (seen.containsAll(unlocked)) return;
    seen.addAll(unlocked);
    _save();
    notifyListeners();
  }

  void setSound(bool v) => _set(() => sound = v);
  void setHaptics(bool v) => _set(() => haptics = v);
  void setNotify(bool v) => _set(() => notify = v);
  void flag(void Function(RubbleStore s) f) => _set(() => f(this));

  void _set(VoidCallback f) {
    f();
    _save();
    notifyListeners();
  }

  // --- salvataggio -----------------------------------------------------------

  void _read(String? raw) {
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      grams = (m['g'] as num).toInt();
      inkBlackMl = (m['ib'] as num?)?.toInt() ?? 0;
      inkWhiteMl = (m['iw'] as num?)?.toInt() ?? 0;
      octoSkin = m['os'] as String? ?? 'squadra';
      fusionSeen = m['fs'] == true;
      octoNewsSeen = m['nv'] == true;
      octoRecent.addAll((m['oc'] as List? ?? const []).cast<int>());
      octoPinned.addAll((m['op'] as List? ?? const []).cast<int>());
      unlocked.addAll((m['u'] as List).cast<String>());
      seen.addAll((m['seen'] as List? ?? const []).cast<String>());
      milestonesDone.addAll((m['ms'] as List? ?? const []).cast<String>());
      skinId = m['skin'] as String? ?? 'smash';
      sound = m['snd'] as bool? ?? true;
      haptics = m['hap'] as bool? ?? true;
      lifetime = m['life'] as bool? ?? false;
      firstEvolutionDone = m['fe'] as bool? ?? false;
      collectionHintShown = m['ch'] as bool? ?? false;
      sleepToastShown = m['st'] as bool? ?? false;
      recoveryOffered = m['ro'] as bool? ?? false;
      lifetimeOffered = m['lo'] as bool? ?? false;
      notify = m['ntf'] as bool? ?? true;
      notifyAsked = m['na'] as bool? ?? false;
      // controllo di coerenza: le skin vanno con i chili
      for (final e in kEvolutions) {
        if (kg >= e.thresholdKg) unlocked.add(e.id);
      }
      if (!isUnlocked(skin)) skinId = 'smash';
    } catch (_) {}
  }

  String encode() => jsonEncode({
    'g': grams,
    'ib': inkBlackMl,
    'iw': inkWhiteMl,
    'os': octoSkin,
    'fs': fusionSeen,
    'nv': octoNewsSeen,
    'oc': octoRecent,
    'op': octoPinned,
    'u': unlocked.toList(),
    'seen': seen.toList(),
    'ms': milestonesDone.toList(),
    'skin': skinId,
    'snd': sound,
    'hap': haptics,
    'life': lifetime,
    'fe': firstEvolutionDone,
    'ch': collectionHintShown,
    'st': sleepToastShown,
    'ro': recoveryOffered,
    'lo': lifetimeOffered,
    'ntf': notify,
    'na': notifyAsked,
  });

  void _save() {
    final raw = encode();
    try {
      _prefs?.setString(_key, raw);
    } catch (_) {}
    if (_cloud) CloudSave.write(raw);
  }

  /// Unisce una copia arrivata dall'account (telefono nuovo, reinstallazione,
  /// altro dispositivo). Non si perde mai niente: si tengono i chili più alti
  /// e tutto ciò che è stato sbloccato o già fatto da una delle due parti.
  /// `true` se è cambiato qualcosa.
  bool mergeFrom(String raw) {
    final o = RubbleStore._(null).._read(raw);
    if (o.grams == 0 && o.unlocked.length <= 1 && !o.lifetime) return false;
    final before = encode();
    final wasEmpty = grams == 0 && unlocked.length <= 1;
    if (o.grams > grams) grams = o.grams;
    if (o.inkBlackMl > inkBlackMl) inkBlackMl = o.inkBlackMl;
    if (o.inkWhiteMl > inkWhiteMl) inkWhiteMl = o.inkWhiteMl;
    unlocked.addAll(o.unlocked);
    seen.addAll(o.seen);
    milestonesDone.addAll(o.milestonesDone);
    lifetime = lifetime || o.lifetime;
    firstEvolutionDone = firstEvolutionDone || o.firstEvolutionDone;
    collectionHintShown = collectionHintShown || o.collectionHintShown;
    sleepToastShown = sleepToastShown || o.sleepToastShown;
    recoveryOffered = recoveryOffered || o.recoveryOffered;
    lifetimeOffered = lifetimeOffered || o.lifetimeOffered;
    notifyAsked = notifyAsked || o.notifyAsked;
    for (final c in o.octoPinned) {
      if (!octoPinned.contains(c) && octoPinned.length < maxPinned) {
        octoPinned.add(c);
        octoRecent.remove(c);
      }
    }
    if (octoRecent.isEmpty) {
      octoRecent.addAll(o.octoRecent.where((c) => !octoPinned.contains(c)));
    }
    // su un'app appena installata si riprendono anche skin e impostazioni
    if (wasEmpty) {
      skinId = o.skinId;
      sound = o.sound;
      haptics = o.haptics;
      notify = o.notify;
    }
    for (final e in kEvolutions) {
      if (kg >= e.thresholdKg) unlocked.add(e.id);
    }
    if (!isUnlocked(skin)) skinId = 'smash';
    if (encode() == before) return false;
    _save();
    notifyListeners();
    return true;
  }

  // --- codice di recupero ----------------------------------------------------

  /// Codice corto con il totale, le skin sbloccate e quella in uso, più una
  /// firma che scoraggia i codici inventati. Es. `K7QD-2MXA-9F3R`.
  String recoveryCode() =>
      RecoveryCode.encode(grams: grams, unlocked: unlocked, skinId: skinId);

  /// Applica un codice: si tiene sempre il valore più alto. `false` se il
  /// codice non è valido.
  bool applyRecoveryCode(String code) {
    final r = RecoveryCode.decode(code);
    if (r == null) return false;
    if (r.grams > grams) grams = r.grams;
    // dal codice arrivano solo i personaggi delle macerie: Tycoon è
    // dell'acquisto a vita e torna solo con "Ripristina acquisti"
    unlocked.addAll(
      r.unlocked.where((id) => skinById(id).unlock != Unlock.lifetime),
    );
    for (final e in kEvolutions) {
      if (kg >= e.thresholdKg) unlocked.add(e.id);
    }
    if (isUnlocked(skinById(r.skinId))) skinId = r.skinId;
    _save();
    notifyListeners();
    return true;
  }
}

class RecoveryCode {
  RecoveryCode._(this.grams, this.unlocked, this.skinId);
  final int grams;
  final Set<String> unlocked;
  final String skinId;

  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const _salt = 'smash-mangia-macerie-2026';

  static int _sign(BigInt payload) {
    // FNV-1a a 32 bit su sale + dati, ridotto a 21 bit
    // la moltiplicazione è spezzata in due perché nel browser i numeri
    // oltre 2^53 perdono precisione: così il codice è identico su app e web
    var h = 0x811c9dc5;
    for (final c in '$_salt:$payload'.codeUnits) {
      h ^= c;
      // h * 0x01000193 = h * 2^24 + h * 0x193, tutto modulo 2^32
      h = ((h & 0xFF) * 0x1000000 + h * 0x193) % 0x100000000;
    }
    return h & 0x1FFFFF;
  }

  static String encode({
    required int grams,
    required Set<String> unlocked,
    required String skinId,
  }) {
    var bits = 0;
    for (var i = 0; i < kSkins.length; i++) {
      // Tycoon (acquisto a vita) non entra nel codice
      if (kSkins[i].unlock == Unlock.lifetime) continue;
      if (unlocked.contains(kSkins[i].id)) bits |= 1 << i;
    }
    final si = kSkins.indexWhere((s) => s.id == skinId).clamp(0, 7);
    final g = grams.clamp(0, (1 << 30) - 1);
    final payload =
        (BigInt.from(g) << 9) | BigInt.from(bits << 3) | BigInt.from(si);
    final all = (payload << 21) | BigInt.from(_sign(payload));
    final sb = StringBuffer();
    var v = all;
    for (var i = 0; i < 12; i++) {
      sb.write(_alphabet[(v & BigInt.from(31)).toInt()]);
      v = v >> 5;
    }
    final s = sb.toString().split('').reversed.join();
    return '${s.substring(0, 4)}-${s.substring(4, 8)}-${s.substring(8)}';
  }

  static RecoveryCode? decode(String raw) {
    final s = raw
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceAll('O', '0')
        .replaceAll(RegExp('[IL]'), '1');
    if (s.length != 12) return null;
    var v = BigInt.zero;
    for (final ch in s.split('')) {
      final k = _alphabet.indexOf(ch);
      if (k < 0) return null;
      v = (v << 5) | BigInt.from(k);
    }
    final sig = (v & BigInt.from(0x1FFFFF)).toInt();
    final payload = v >> 21;
    if (_sign(payload) != sig) return null;
    final si = (payload & BigInt.from(7)).toInt();
    final bits = ((payload >> 3) & BigInt.from(63)).toInt();
    final grams = (payload >> 9).toInt();
    return RecoveryCode._(grams, {
      for (var i = 0; i < kSkins.length; i++)
        if (bits & (1 << i) != 0) kSkins[i].id,
    }, si < kSkins.length ? kSkins[si].id : 'smash');
  }
}
