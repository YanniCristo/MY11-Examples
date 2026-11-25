import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/rubble/application/rubble_store.dart';
import 'package:smashcrop/features/rubble/domain/rubble_math.dart';
import 'package:smashcrop/features/rubble/domain/skins.dart';

void main() {
  group('conti delle macerie', () {
    test('un A4 intero pesa circa 4,7 kg, una fascia tipica circa 0,75', () {
      // A4 in punti PDF a 1 pixel per punto: 595 × 842
      const mm = RubbleMath.pdfMmPerPt;
      final whole = RubbleMath.kgOf(
        CutOperation(
          orientation: CutOrientation.horizontal,
          start: 0,
          end: 842,
          lengthBefore: 843,
        ),
        595,
        mm,
      );
      expect(whole, closeTo(4.68, .05));
      final strip = RubbleMath.kgOf(
        CutOperation(
          orientation: CutOrientation.horizontal,
          start: 100,
          end: 235,
          lengthBefore: 842,
        ),
        595,
        mm,
      );
      expect(strip, closeTo(.75, .02));
    });

    test('formato: al massimo 3 cifre, 4 solo oltre 999', () {
      expect(RubbleMath.format(.3, comma: true), '0,30');
      expect(RubbleMath.format(1.254, comma: true), '1,25');
      expect(RubbleMath.format(12.44, comma: true), '12,4');
      expect(RubbleMath.format(150.7, comma: true), '150');
      expect(RubbleMath.format(1500, comma: true), '1.500');
      expect(RubbleMath.format(1500, comma: false), '1,500');
      expect(RubbleMath.format(12.44, comma: false), '12.4');
    });

    test('barra e prossima evoluzione', () {
      expect(RubbleMath.next(0)!.id, 'burp');
      expect(RubbleMath.progress(75), closeTo(.5, 1e-9));
      expect(RubbleMath.next(150)!.id, 'popcorn');
      expect(RubbleMath.progress(300), closeTo(.5, 1e-9));
      expect(RubbleMath.next(5000), isNull);
      expect(RubbleMath.progress(5000), 1);
    });
  });

  group('contatore', () {
    test('le evoluzioni si sbloccano e si indossano da sole', () {
      final s = RubbleStore.memory();
      var g = s.add(14.9);
      expect(g.milestones, isEmpty);
      g = s.add(0.2);
      expect(g.milestones, ['secchio'], reason: 'tappa del secchio a 15 kg');
      g = s.add(140);
      expect(g.evolutions.map((e) => e.id), ['burp']);
      expect(s.skinId, 'burp');
      expect(s.hasNew, isTrue);
      s.markSeen();
      expect(s.hasNew, isFalse);
      // un salto enorme sblocca tutto in una volta
      g = s.add(5000);
      expect(g.evolutions.map((e) => e.id), ['popcorn', 'muahaha', 'mammamia']);
      expect(
        s.isUnlocked(skinById('tycoon')),
        isFalse,
        reason: 'Tycoon solo con l\'acquisto a vita',
      );
    });

    test('codice di recupero: si tiene il valore più alto', () {
      final a = RubbleStore.memory()..add(460);
      a.choose(skinById('burp'));
      final code = a.recoveryCode();
      expect(code, matches(RegExp(r'^[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}$')));

      final b = RubbleStore.memory()..add(10);
      expect(
        b.applyRecoveryCode(code.toLowerCase().replaceAll('-', ' ')),
        isTrue,
      );
      expect(b.kg, closeTo(460, .001));
      expect(b.isUnlocked(skinById('popcorn')), isTrue);
      expect(b.skinId, 'burp');

      final c = RubbleStore.memory()..add(900);
      expect(c.applyRecoveryCode(code), isTrue);
      expect(c.kg, closeTo(900, .001), reason: 'non scende mai');
    });

    test('un codice inventato o sbagliato viene rifiutato', () {
      final s = RubbleStore.memory();
      final code = (RubbleStore.memory()..add(200)).recoveryCode();
      final wrong =
          code.substring(0, 5) +
          (code[5] == 'A' ? 'B' : 'A') +
          code.substring(6);
      expect(s.applyRecoveryCode(wrong), isFalse);
      expect(s.applyRecoveryCode('ABCD-EFGH'), isFalse);
      expect(s.kg, 0);
    });

    test('il salvataggio si rilegge uguale', () {
      final s = RubbleStore.memory()
        ..add(160)
        ..setSound(false);
      final raw = s.encode();
      expect(raw, contains('"g":160000'));
      expect(raw, contains('"snd":false'));
    });
  });

  group('copia nell\'account (iCloud / Block Store)', () {
    test('app reinstallata: riprende chili, skin e impostazioni', () {
      final old = RubbleStore.memory()..add(200);
      old.setSound(false);
      final fresh = RubbleStore.memory();
      expect(fresh.mergeFrom(old.encode()), isTrue);
      expect(fresh.grams, old.grams);
      expect(fresh.unlocked, containsAll(['smash', 'burp']));
      expect(fresh.skinId, 'burp');
      expect(fresh.sound, isFalse);
    });

    test('due copie diverse: chili più alti e skin di entrambe', () {
      final a = RubbleStore.memory()..add(500);
      a.choose(skinById('smash'));
      final b = RubbleStore.memory()..add(20);
      expect(b.mergeFrom(a.encode()), isTrue);
      expect(b.grams, a.grams);
      expect(b.unlocked, containsAll(['burp', 'popcorn']));
      // chi aveva già usato l'app tiene la sua skin
      expect(b.skinId, 'smash');
    });

    test('il contatore non scende mai', () {
      final small = RubbleStore.memory()..add(10);
      final big = RubbleStore.memory()..add(100);
      final g = big.grams;
      expect(big.mergeFrom(small.encode()), isFalse);
      expect(big.grams, g);
    });

    test('copia vuota o rovinata: non cambia niente', () {
      final s = RubbleStore.memory()..add(50);
      final before = s.encode();
      expect(s.mergeFrom(RubbleStore.memory().encode()), isFalse);
      expect(s.mergeFrom('non è json'), isFalse);
      expect(s.encode(), before);
    });

    test('acquisto a vita: resta vero', () {
      final a = RubbleStore.memory()..flag((s) => s.lifetime = true);
      final b = RubbleStore.memory()..add(30);
      b.mergeFrom(a.encode());
      expect(b.lifetime, isTrue);
    });
  });
}
