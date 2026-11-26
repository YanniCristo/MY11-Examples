import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashcrop/features/editor/application/editor_controller.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/selection_state.dart';
import 'package:smashcrop/features/image_processing/services/image_loader.dart';
import 'package:smashcrop/features/settings/preferences.dart';

Future<ui.Image> solidImage(int w, int h) async {
  final px = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 200);
  final buf = await ui.ImmutableBuffer.fromUint8List(px);
  final desc = ui.ImageDescriptor.raw(
    buf,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await desc.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

void main() {
  // queste prove misurano i tagli tra i centri delle linee: linee senza
  // spessore (lo spessore ha la sua prova in editor_controller_test)
  setUp(() => EditorController.selectionLineWidth = 0);
  tearDown(() => EditorController.selectionLineWidth = 3);

  late AppPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await AppPreferences.load();
  });

  Future<EditorController> make(
    WidgetTester tester, {
    bool smash = true,
  }) async {
    final img = (await tester.runAsync(() => solidImage(300, 600)))!;
    final c =
        EditorController.image(
            image: LoadedImage(
              image: img,
              format: OutputFormat.png,
              name: 't.png',
            ),
            preferences: prefs,
          )
          ..setViewportSize(const ui.Size(360, 480))
          ..smashAvailable = true;
    c.setSmash(smash);
    return c;
  }

  for (final smash in [true, false]) {
    testWidgets('taglio completo con SMASH ${smash ? 'attivo' : 'spento'}', (
      tester,
    ) async {
      final c = await make(tester, smash: smash);
      c.selection = c.selection.withLines(
        CutOrientation.horizontal,
        const LinePair(100, 250),
      );
      expect(c.removePortion(), isTrue);
      expect(
        c.selectionVisible,
        isFalse,
        reason: 'le linee spariscono durante il taglio',
      );
      expect(c.canCut, isFalse, reason: 'niente doppio comando');

      final tl = c.animation!.timeline;
      c.tick(Duration(milliseconds: (tl.joinEndMs - 1).floor()));
      expect(
        c.doc.height,
        600,
        reason: 'prima del ricongiungimento il documento non cambia',
      );
      c.tick(Duration(milliseconds: tl.joinEndMs.ceil()));
      expect(c.doc.height, 450);
      expect(c.canUndo, isTrue);

      // la nuova selezione arriva dopo la pausa, contata dal ricongiungimento
      await tester.pump(
        c.settings.reappearDelay - const Duration(milliseconds: 20),
      );
      expect(c.selectionVisible, isFalse);
      await tester.pump(const Duration(milliseconds: 40));
      if (smash) {
        // SMASH è ancora in scena: la selezione aspetta che esca
        expect(c.selectionVisible, isFalse);
        c.tick(Duration(milliseconds: tl.endMs.ceil() + 1));
      }
      expect(c.selectionVisible, isTrue);
      expect(c.selection.mode, CutOrientation.horizontal);
      expect(c.selection.active!.high, lessThanOrEqualTo(450));

      c.tick(Duration(milliseconds: tl.endMs.ceil() + 1));
      expect(c.isAnimating, isFalse);

      c.undo();
      expect(c.doc.height, 600);
      c.redo();
      expect(c.doc.height, 450);
      c.dispose();
    });
  }

  testWidgets('sparisce anche ciò che sta sotto le linee rosse', (
    tester,
  ) async {
    EditorController.selectionLineWidth = 3;
    for (final mode in CutOrientation.values) {
      final c = await make(tester, smash: false);
      final horizontal = mode == CutOrientation.horizontal;
      final length = horizontal ? 600 : 300;
      final base = horizontal
          ? c.selection
          : c.selection.tap(mode, width: 300, height: 600);
      c.selection = base.withLines(mode, const LinePair(100, 200));
      // pixel del documento coperti da mezza linea, allo zoom attuale
      double s(double v) => horizontal
          ? c.contentToScreen(ui.Offset(0, v)).dy
          : c.contentToScreen(ui.Offset(v, 0)).dx;
      final half = 1.5 / (s(1) - s(0)).abs();
      final lo = (100 - half).floor(), hi = (200 + half).ceil();
      expect(hi - lo, greaterThan(100), reason: 'più largo dei soli centri');
      expect(c.removePortion(), isTrue);
      c.tick(const Duration(seconds: 10));
      expect(horizontal ? c.doc.height : c.doc.width, length - (hi - lo));
      c.dispose();
    }
  });

  testWidgets('risultato identico con e senza SMASH', (tester) async {
    final a = await make(tester, smash: true);
    final b = await make(tester, smash: false);
    for (final c in [a, b]) {
      c.selection = c.selection
          .tap(CutOrientation.vertical, width: 300, height: 600)
          .withLines(CutOrientation.vertical, const LinePair(220, 40));
      c.removePortion();
      c.tick(const Duration(seconds: 10));
    }
    expect(a.doc.width, 120);
    expect(a.doc.tiles(), b.doc.tiles());
    a.dispose();
    b.dispose();
  });

  testWidgets('con la selezione nascosta non si taglia', (tester) async {
    final c = await make(tester);
    c.tapOrientation(CutOrientation.horizontal);
    expect(c.selectionVisible, isFalse);
    expect(c.canCut, isFalse);
    expect(c.removePortion(), isFalse);
    c.tapOrientation(CutOrientation.horizontal);
    expect(c.canCut, isTrue);
    c.dispose();
  });

  testWidgets('la preferenza SMASH viene ricordata', (tester) async {
    final c = await make(tester);
    c.setSmash(false);
    final again = await AppPreferences.load();
    expect(again.smashEnabled, isFalse);
    c.dispose();
  });
}
