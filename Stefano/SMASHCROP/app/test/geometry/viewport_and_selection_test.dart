import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/selection_state.dart';
import 'package:smashcrop/features/editor/domain/viewport_transform.dart';

void main() {
  group('viewport', () {
    final t = ViewportTransform(
      viewport: const Size(400, 500),
      content: const Size(1080, 1920),
      gutters: Gutters.forOrientation(CutOrientation.horizontal),
    );

    test('a 1.0x il documento è intero, centrato e non deformato', () {
      final r = t.contentRect;
      expect(r.height, closeTo(500 - 16, 1e-9));
      expect(r.width / r.height, closeTo(1080 / 1920, 1e-9));
      expect(r.center.dx, closeTo(200, 1e-9));
      expect(r.left, greaterThanOrEqualTo(Gutters.handle));
    });

    test('andata e ritorno tra coordinate senza deriva', () {
      final z = t.zoomedAround(const Offset(150, 300), 3.3).panned(const Offset(-40, 25));
      for (final p in const [Offset(0, 0), Offset(540, 960), Offset(1079, 1919)]) {
        final back = z.screenToContent(z.contentToScreen(p));
        expect((back - p).distance, lessThan(1e-6));
      }
    });

    test('lo zoom tiene fermo il punto sotto le dita', () {
      const focal = Offset(260, 120);
      final before = t.screenToContent(focal);
      final z = t.zoomedAround(focal, 2.5);
      expect((z.screenToContent(focal) - before).distance, lessThan(1e-6));
    });

    test('lo zoom non cambia le coordinate del taglio', () {
      // la linea a y=800 del documento resta y=800 qualunque sia lo zoom
      final z = t.zoomedAround(const Offset(200, 250), 4).panned(const Offset(30, -60));
      final screenY = z.contentToScreen(const Offset(0, 800)).dy;
      expect(z.screenToContent(Offset(0, screenY)).dy, closeTo(800, 1e-6));
    });

    test('lo spostamento è limitato ai bordi del documento', () {
      final far = t.copyWith(zoom: 2, pan: const Offset(10000, 10000));
      final r = far.contentRect;
      expect(r.top, closeTo(far.fitArea.top, 1e-6));
      expect(far.copyWith(zoom: 1).pan, Offset.zero);
    });

    test('margini per le maniglie sull\'asse giusto', () {
      final h = Gutters.forOrientation(CutOrientation.horizontal);
      final v = Gutters.forOrientation(CutOrientation.vertical);
      expect(h.left, Gutters.handle);
      expect(h.top, Gutters.base);
      expect(v.top, Gutters.handle);
      expect(v.left, Gutters.base);
    });
  });

  group('selezione', () {
    SelectionState s() => SelectionState.initial(width: 1000, height: 2000);

    test('si apre in orizzontale', () {
      expect(s().mode, CutOrientation.horizontal);
      expect(s().active!.low, lessThan(s().active!.high));
    });

    test('premere la modalità attiva nasconde, ripremere ripristina', () {
      var x = s().withLines(CutOrientation.horizontal, const LinePair(300, 900));
      x = x.tap(CutOrientation.horizontal, width: 1000, height: 2000);
      expect(x.isVisible, isFalse);
      x = x.tap(CutOrientation.horizontal, width: 1000, height: 2000);
      expect(x.mode, CutOrientation.horizontal);
      expect(x.active, const LinePair(300, 900));
    });

    test('la modalità opposta sostituisce senza passare da nascosto', () {
      final x = s().tap(CutOrientation.vertical, width: 1000, height: 2000);
      expect(x.mode, CutOrientation.vertical);
    });

    test('coordinate non più valide tornano alla posizione iniziale', () {
      var x = s().withLines(CutOrientation.horizontal, const LinePair(1500, 1900));
      x = x.hidden().ensureValid(width: 1000, height: 1200);
      x = x.tap(CutOrientation.horizontal, width: 1000, height: 1200);
      expect(x.active!.high, lessThanOrEqualTo(1200));
    });

    test('dopo un taglio stessa direzione e fascia dentro il documento', () {
      final x = s().afterCut(CutOrientation.vertical, width: 700, height: 2000);
      expect(x.mode, CutOrientation.vertical);
      expect(x.active!.high, lessThanOrEqualTo(700));
    });
  });
}
