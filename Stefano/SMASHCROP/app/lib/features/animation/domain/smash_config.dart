import 'dart:ui';

/// Metadati dei frame ufficiali di SMASH (`assets/smash/smash_01..18.webp`).
///
/// Tutti i frame hanno la stessa tela (730×470) e il robot è già nella
/// posizione giusta per quel momento del movimento. Le coordinate qui sotto
/// sono in pixel del frame.
class SmashSprite {
  const SmashSprite._();

  static const int frameCount = 18;
  static const Size frameSize = Size(730, 470);

  static String asset(int i) =>
      'assets/smash/smash_${(i + 1).toString().padLeft(2, '0')}.webp';

  /// Punto di contatto del pugno nel frame d'impatto (006).
  static const Offset impactAnchor = Offset(485, 215);

  /// Sommità della testa e appoggio dei piedi: servono a ricavare la scala.
  static const double headY = 75;
  static const double feetY = 350;
  static double get bodyHeight => feetY - headY;

  /// Bordo destro del robot nel primo frame e bordo sinistro nell'ultimo:
  /// servono per farlo partire e finire completamente fuori dal viewport.
  static const double firstFrameRight = 115;
  static const double lastFrameLeft = 566;

  /// Durata di ogni frame in "unità" (1 unità = 1 fotogramma alla velocità
  /// scelta). Il pollice alzato resta un po' di più.
  static const List<int> frameUnits = [
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 1, 1, //
  ];

  /// Indici (da 0) delle fasi.
  static const int impactFrame = 5; // frame 006: il pugno colpisce
  static const int entryEndFrame = 3; // fino al 003 sta entrando
  static const int exitStartFrame = 16; // dal 017 esce di corsa
}

/// Impostazioni dell'animazione, scelte con la pagina di prova (24/11/2026).
class CutAnimationSettings {
  const CutAnimationSettings({
    this.framesPerSecond = 10,
    this.robotHeightFraction = .32,
    this.joinDuration = const Duration(milliseconds: 320),
    this.reappearDelay = const Duration(milliseconds: 800),
    this.joinAfterImpactFrames = 2,
    this.plainFadeDuration = const Duration(milliseconds: 140),
    this.shatterDuration = const Duration(milliseconds: 550),
  });

  final double framesPerSecond;

  /// Altezza del robot rispetto alla larghezza del viewport.
  final double robotHeightFraction;
  final Duration joinDuration;

  /// Pausa tra il ricongiungimento completato e la nuova selezione
  /// (intervallo consentito 500–800 ms).
  final Duration reappearDelay;
  final int joinAfterImpactFrames;

  /// Senza SMASH: dissolvenza della fascia prima del ricongiungimento.
  final Duration plainFadeDuration;
  final Duration shatterDuration;
}
