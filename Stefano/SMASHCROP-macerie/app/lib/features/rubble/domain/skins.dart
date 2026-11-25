import 'dart:ui';

import '../../../app/strings.dart';

/// Come si sblocca una skin.
enum Unlock { start, rubble, lifetime }

/// Un personaggio di SMASH: 18 immagini, 6 elementi della fascia, 2 teste,
/// la posa da eroe e i suoi suoni. Aggiungere una skin = una voce qui sotto
/// e una cartella in `assets/rubble/<id>/`.
class SkinDef {
  const SkinDef({
    required this.id,
    required this.unlock,
    this.thresholdKg = 0,
    this.goal,
    required this.impactAnchor,
    required this.sounds,
    required this.color,
  });

  final String id;
  final Unlock unlock;

  /// Chili di macerie che la sbloccano (solo [Unlock.rubble]).
  final double thresholdKg;

  /// Oggetto da cantiere da riempire (nome del file in `obiettivi/`).
  final String? goal;

  /// Punto del colpo nell'immagine 6 (tela 730×470).
  final Offset impactAnchor;
  final List<String> sounds;

  /// Colore del personaggio, per bordi e luci della Collezione.
  final Color color;

  String get dir => 'assets/rubble/$id';
  String frame(int i) => '$dir/f_${(i + 1).toString().padLeft(2, '0')}.webp';
  String element(int i) => '$dir/e_${i + 1}.webp';
  String get head => '$dir/testa.webp';
  String get headSleep => '$dir/testa_dorme.webp';
  String get pose => '$dir/posa.webp';
  String? get goalImage =>
      goal == null ? null : 'assets/rubble/obiettivi/$goal.webp';

  String get name => switch (id) {
    'smash' => 'SMASH',
    'burp' => 'SMASH Burp',
    'popcorn' => 'SMASH Popcorn',
    'muahaha' => 'SMASH Muahaha',
    'mammamia' => 'SMASH Mamma Mia',
    _ => 'SMASH Tycoon',
  };

  /// "Riempi una carriola" ecc.
  String get goalLabel => switch (goal) {
    'carriola' => S.fillWheelbarrow,
    'betoniera' => S.fillMixer,
    'cassone' => S.fillSkip,
    'camioncino' => S.fillTruck,
    _ => unlock == Unlock.lifetime ? S.lifetimeName : S.starter,
  };
}

const _sounds4 = [1, 2, 3, 4];
List<String> _s(String base) => [
  for (final i in _sounds4) 'sounds/${base}_$i.mp3',
];

/// Le skin nell'ordine delle evoluzioni; Tycoon è quella dell'acquisto a vita.
final List<SkinDef> kSkins = [
  SkinDef(
    id: 'smash',
    unlock: Unlock.start,
    impactAnchor: const Offset(485, 215),
    sounds: _s('colpo_smash'),
    color: const Color(0xFFE5172F),
  ),
  SkinDef(
    id: 'burp',
    unlock: Unlock.rubble,
    thresholdKg: 150,
    goal: 'carriola',
    impactAnchor: const Offset(485, 192),
    sounds: _s('rutto_burp'),
    color: const Color(0xFF9BC21A),
  ),
  SkinDef(
    id: 'popcorn',
    unlock: Unlock.rubble,
    thresholdKg: 450,
    goal: 'betoniera',
    impactAnchor: const Offset(485, 215),
    sounds: _s('pop_popcorn'),
    color: const Color(0xFFF2B21B),
  ),
  SkinDef(
    id: 'muahaha',
    unlock: Unlock.rubble,
    thresholdKg: 1500,
    goal: 'cassone',
    impactAnchor: const Offset(485, 177),
    sounds: _s('risata_muahaha'),
    color: const Color(0xFF8E2BD8),
  ),
  SkinDef(
    id: 'mammamia',
    unlock: Unlock.rubble,
    thresholdKg: 4500,
    goal: 'camioncino',
    impactAnchor: const Offset(485, 215),
    sounds: _s('mammamia'),
    color: const Color(0xFFE53935),
  ),
  SkinDef(
    id: 'tycoon',
    unlock: Unlock.lifetime,
    impactAnchor: const Offset(485, 215),
    sounds: _s('scorreggia_tycoon'),
    color: const Color(0xFFEF6C00),
  ),
];

SkinDef skinById(String id) =>
    kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);

/// Le skin che si sbloccano con le macerie, in ordine.
List<SkinDef> get kEvolutions => [
  for (final s in kSkins)
    if (s.unlock == Unlock.rubble) s,
];

/// Tappe senza evoluzione: piccole soddisfazioni prima della prima.
const List<(double, String)> kMilestones = [(15, 'secchio')];
