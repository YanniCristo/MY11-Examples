import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/animation/domain/cut_timeline.dart';
import 'package:smashcrop/features/animation/domain/smash_config.dart';

void main() {
  const settings = CutAnimationSettings();
  const viewport = Size(370, 480);

  SmashPlacement place(Offset impact) => SmashPlacement(
      viewport: viewport, impact: impact, robotHeight: viewport.width * .32);

  test('il pugno del frame d\'impatto cade sull\'epicentro', () {
    for (final impact in const [Offset(185, 60), Offset(185, 240), Offset(90, 400)]) {
      final p = place(impact);
      final t = CutTimeline(settings: settings, smash: true);
      final dx = t.robotDx(t.impactMs, p);
      expect(dx, 0, reason: "all'impatto il robot è fermo");
      final fist = p.origin + SmashSprite.impactAnchor * p.scale;
      expect((fist - impact).distance, lessThan(1e-9));
    }
  });

  test('fascia più in alto, robot più in alto', () {
    expect(place(const Offset(185, 80)).origin.dy,
        lessThan(place(const Offset(185, 380)).origin.dy));
  });

  test('entra da sinistra tutto fuori e finisce tutto fuori a destra', () {
    final p = place(const Offset(185, 240));
    final t = CutTimeline(settings: settings, smash: true);
    final right0 = p.origin.dx + t.robotDx(0, p) + SmashSprite.firstFrameRight * p.scale;
    expect(right0, lessThanOrEqualTo(0));
    final endT = t.robotEndMs - 0.001;
    final leftEnd = p.origin.dx + t.robotDx(endT, p) + SmashSprite.lastFrameLeft * p.scale;
    expect(leftEnd, greaterThanOrEqualTo(viewport.width - 0.5));
  });

  test('sequenza: impatto, poi ricongiungimento, poi fine', () {
    final t = CutTimeline(settings: settings, smash: true);
    expect(t.frameAt(0), 0);
    expect(t.frameAt(t.impactMs), SmashSprite.impactFrame);
    expect(t.joinStartMs, greaterThan(t.impactMs));
    expect(t.joinEndMs, t.joinStartMs + settings.joinDuration.inMilliseconds);
    expect(t.frameAt(t.robotEndMs), isNull);
    expect(t.joinProgress(t.joinStartMs), 0);
    expect(t.joinProgress(t.joinEndMs), 1);
  });

  test('senza SMASH nessun robot e ricongiungimento subito dopo la dissolvenza', () {
    final t = CutTimeline(settings: settings, smash: false);
    expect(t.frameAt(0), isNull);
    expect(t.joinStartMs, settings.plainFadeDuration.inMilliseconds);
    expect(t.endMs, t.joinEndMs);
  });

  test('la pausa della nuova selezione è nell\'intervallo previsto', () {
    expect(settings.reappearDelay.inMilliseconds, inInclusiveRange(500, 800));
  });
}
