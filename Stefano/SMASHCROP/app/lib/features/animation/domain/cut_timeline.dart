import 'dart:math' as math;
import 'dart:ui';

import 'smash_config.dart';

/// Dove disegnare SMASH: il pugno del frame d'impatto cade esattamente
/// sull'epicentro della fascia.
class SmashPlacement {
  SmashPlacement({
    required this.viewport,
    required this.impact,
    required double robotHeight,
  }) : scale = robotHeight / SmashSprite.bodyHeight;

  final Size viewport;

  /// Epicentro della fascia in coordinate del viewport.
  final Offset impact;

  /// Punti del viewport per pixel di frame.
  final double scale;

  /// Angolo in alto a sinistra del frame, prima degli spostamenti di
  /// entrata e uscita.
  Offset get origin => impact - SmashSprite.impactAnchor * scale;

  Size get frameSize => SmashSprite.frameSize * scale;

  /// Spostamento iniziale: il robot parte tutto oltre il bordo sinistro.
  double get entryOffset =>
      -(origin.dx + SmashSprite.firstFrameRight * scale) - 4;

  /// Spostamento finale: il robot finisce tutto oltre il bordo destro.
  double get exitOffset =>
      viewport.width - (origin.dx + SmashSprite.lastFrameLeft * scale) + 4;
}

/// Linea del tempo di un taglio animato.
///
/// Tutto è in millisecondi dall'inizio. Il risultato del taglio non dipende
/// da qui: questa classe decide solo cosa si vede e quando.
class CutTimeline {
  CutTimeline({required this.settings, required this.smash}) {
    final fd = 1000 / settings.framesPerSecond;
    var acc = 0.0;
    for (final u in SmashSprite.frameUnits) {
      _starts.add(acc);
      acc += u * fd;
    }
    _robotEnd = acc;
    if (smash) {
      impactMs = _starts[SmashSprite.impactFrame];
      joinStartMs =
          _starts[SmashSprite.impactFrame + settings.joinAfterImpactFrames];
    } else {
      impactMs = 0;
      joinStartMs = settings.plainFadeDuration.inMilliseconds.toDouble();
    }
    joinEndMs = joinStartMs + settings.joinDuration.inMilliseconds;
  }

  final CutAnimationSettings settings;
  final bool smash;
  final List<double> _starts = [];
  late final double _robotEnd;

  /// Momento in cui la fascia si rompe (con SMASH) o inizia a sparire.
  late final double impactMs;
  late final double joinStartMs;

  /// Da qui parte il conteggio della nuova selezione.
  late final double joinEndMs;

  double get endMs => smash ? math.max(_robotEnd, joinEndMs) : joinEndMs;
  double get robotEndMs => smash ? _robotEnd : 0;

  /// Frame di SMASH da mostrare, o `null` se il robot non è in scena.
  int? frameAt(double t) {
    if (!smash || t < 0 || t >= _robotEnd) return null;
    var f = 0;
    while (f < _starts.length - 1 && t >= _starts[f + 1]) {
      f++;
    }
    return f;
  }

  /// Spostamento orizzontale extra del robot (entrata e uscita).
  double robotDx(double t, SmashPlacement p) {
    final enterEnd = _starts[SmashSprite.entryEndFrame];
    if (t < enterEnd) return p.entryOffset * (1 - t / enterEnd);
    final exitStart = _starts[SmashSprite.exitStartFrame];
    if (t >= exitStart) {
      final k = ((t - exitStart) / (_robotEnd - exitStart)).clamp(0.0, 1.0);
      return p.exitOffset * k;
    }
    return 0;
  }

  /// Avanzamento del ricongiungimento, già con la curva ease-in-out.
  double joinProgress(double t) {
    final x = ((t - joinStartMs) / (joinEndMs - joinStartMs)).clamp(0.0, 1.0);
    return x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
  }

  /// Opacità della fascia intera (prima dell'impatto o senza SMASH).
  double stripOpacity(double t) {
    if (smash) return t < impactMs ? 1 : 0;
    return (1 - t / joinStartMs).clamp(0.0, 1.0);
  }

  /// Secondi trascorsi dall'esplosione della fascia, o `null`.
  double? shatterSeconds(double t) {
    if (!smash || t < impactMs) return null;
    final s = (t - impactMs) / 1000;
    return s * 1000 > settings.shatterDuration.inMilliseconds ? null : s;
  }
}
