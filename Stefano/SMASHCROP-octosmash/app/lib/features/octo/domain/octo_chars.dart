import 'dart:ui' show Color;

import 'ink_math.dart';

/// Un personaggio della Collezione di OctoSmash.
class OctoChar {
  const OctoChar({
    required this.id,
    required this.name,
    required this.color,
    this.goal,
    this.lifetime = false,
    this.ready = true,
  });

  /// 'squadra' (i 4 di base) o il nome dell'evoluzione (fusione, stampa...).
  final String id;
  final String name;

  /// Colore d'accento nella Collezione.
  final Color color;

  /// Indice del contenitore che lo sblocca (InkMath.goals), se c'è.
  final int? goal;

  /// Si ottiene solo con l'acquisto "a vita".
  final bool lifetime;

  /// Le sue grafiche sono già arrivate (gli altri sono "in arrivo").
  final bool ready;

  bool get isSquad => id == 'squadra';

  String get head => 'assets/octo/teste/${isSquad ? 'bianco' : id}_testa.webp';

  String get headSleep =>
      'assets/octo/teste/${isSquad ? 'bianco' : id}_testa_dorme.webp';

  double get litres => goal == null ? 0 : InkMath.goals[goal!];

  String? get goalName => goal == null ? null : InkMath.goalNames[goal!];

  String? get goalWithArticle =>
      goal == null ? null : InkMath.goalWithArticle[goal!];

  /// Immagine del contenitore che lo sblocca.
  String? get goalImage => goal == null
      ? null
      : 'assets/octo/contenitori/${InkMath.goalNames[goal!].toLowerCase()}.webp';
}

/// Prototipo: tutte le evoluzioni pronte sono sbloccate per provarle.
const bool kOctoUnlockAllForTesting = true;

const List<OctoChar> kOctoChars = [
  OctoChar(id: 'squadra', name: 'La Squadra', color: Color(0xFF22E4F2)),
  OctoChar(
    id: 'fusione',
    name: 'OctoSmash Fusione',
    color: Color(0xFFB98CFF),
    goal: 0,
  ),
  OctoChar(
    id: 'stampa',
    name: 'OctoSmash Stampa',
    color: Color(0xFFB8C2CC),
    goal: 1,
  ),
  OctoChar(
    id: 'abisso',
    name: 'OctoSmash Abisso',
    color: Color(0xFF2F6BFF),
    goal: 2,
  ),
  OctoChar(
    id: 'diluvio',
    name: 'OctoSmash Diluvio',
    color: Color(0xFF3FA7B5),
    goal: 3,
  ),
  OctoChar(
    id: 'imperatore',
    name: 'OctoSmash Imperatore',
    color: Color(0xFFE0B64A),
    lifetime: true,
    ready: false,
  ),
];

OctoChar octoCharById(String id) =>
    kOctoChars.firstWhere((c) => c.id == id, orElse: () => kOctoChars.first);

/// Sbloccato con i litri raccolti (o con "a vita").
bool octoUnlocked(OctoChar c, double litres, {required bool lifetime}) {
  if (!c.ready) return false;
  if (c.isSquad) return true;
  if (kOctoUnlockAllForTesting) return true;
  if (c.lifetime) return lifetime;
  return litres >= c.litres;
}
