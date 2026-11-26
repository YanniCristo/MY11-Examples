import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashcrop/features/editor/application/editor_controller.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/selection_state.dart';
import 'package:smashcrop/features/image_processing/services/image_loader.dart';
import 'package:smashcrop/features/settings/preferences.dart';

Uint8List png(int w, int h, int shade) {
  final i = img.Image(width: w, height: h);
  for (final p in i) {
    p
      ..r = shade
      ..g = p.y % 256
      ..b = p.x % 256;
  }
  return img.encodePng(i);
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

  /// Tre immagini di misure diverse; decodificate subito solo le prime due,
  /// come fa il caricamento vero.
  Future<EditorController> three(WidgetTester tester) async {
    const sizes = [(120, 200), (200, 120), (90, 300)];
    final files = <ImageFile>[];
    final decoded = <ui.Image?>[];
    for (var i = 0; i < sizes.length; i++) {
      final (w, h) = sizes[i];
      final bytes = png(w, h, 40 * i);
      final l = (await tester.runAsync(
        () => ImageLoader.decode(bytes, 'foto_$i.png'),
      ))!;
      files.add(l.file);
      if (i < ImageLoader.decodedAhead) {
        decoded.add(l.image);
      } else {
        l.image.dispose();
        decoded.add(null);
      }
    }
    return EditorController.images(
        images: PickedImages(files, decoded),
        preferences: prefs,
      )
      ..setViewportSize(const ui.Size(360, 480))
      ..smashAvailable = true
      ..setSmash(false);
  }

  Future<void> cut(
    WidgetTester tester,
    EditorController c,
    int a,
    int b,
  ) async {
    c.selection = c.selection.withLines(
      CutOrientation.horizontal,
      LinePair(a.toDouble(), b.toDouble()),
    );
    expect(c.removePortion(), isTrue);
    c.tick(const Duration(seconds: 10));
    c.tick(const Duration(seconds: 20));
  }

  testWidgets('più immagini diventano pagine da scorrere', (tester) async {
    final c = await three(tester);
    expect(c.isPdf, isFalse);
    expect(c.hasPages, isTrue);
    expect(c.multiImage, isTrue);
    expect(c.pageCount, 3);
    expect(c.pages[2].isReady, isFalse, reason: 'la terza si decodifica dopo');

    c.goToPage(2);
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    expect(c.pageIndex, 2);
    expect(c.pageReady, isTrue);
    expect(c.doc.width, 90);
    expect(c.doc.height, 300);
    c.dispose();
  });

  testWidgets('ogni immagine ha i suoi tagli', (tester) async {
    final c = await three(tester);
    await cut(tester, c, 50, 100);
    expect(c.pages[0].doc.height, 150);
    c.goToPage(1);
    expect(c.doc.height, 120, reason: 'la seconda non è toccata');
    expect(c.canUndo, isFalse);
    c.goToPage(0);
    expect(c.canUndo, isTrue);
    c.dispose();
  });

  testWidgets('in memoria restano solo poche immagini decodificate', (
    tester,
  ) async {
    final c = await three(tester);
    for (final i in [1, 2, 0, 2]) {
      c.goToPage(i);
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 100)),
      );
    }
    final ready = c.pages.where((p) => p.isReady).length;
    expect(ready, lessThanOrEqualTo(EditorController.keptPages));
    c.dispose();
  });

  testWidgets('immagini separate: ognuna nel suo formato, numerate', (
    tester,
  ) async {
    final c = await three(tester);
    await cut(tester, c, 50, 100);
    final files = (await tester.runAsync(c.buildImageExports))!;
    expect(files.length, 3);
    expect(files.map((f) => f.fileName.split('_').last).toList(), [
      '01.png',
      '02.png',
      '03.png',
    ]);
    final first = img.decodePng(files[0].bytes)!;
    expect(first.width, 120);
    expect(first.height, 150);
    final third = img.decodePng(files[2].bytes)!;
    expect(third.height, 300);
    c.dispose();
  });

  testWidgets('una sola immagine: come prima, nessuna pagina', (tester) async {
    final bytes = png(100, 100, 10);
    final l = (await tester.runAsync(
      () => ImageLoader.decode(bytes, 'a.png'),
    ))!;
    final c = EditorController.images(
      images: PickedImages.single(l),
      preferences: prefs,
    );
    expect(c.hasPages, isFalse);
    expect(c.multiImage, isFalse);
    final files = (await tester.runAsync(c.buildImageExports))!;
    expect(files.single.fileName.endsWith('.png'), isTrue);
    // il nome contiene anche l'ora (alle 01:xx c'è "_01"): si guarda solo la fine
    expect(files.single.fileName.endsWith('_01.png'), isFalse);
    c.dispose();
  });

  testWidgets('aggiungere immagini non tocca quelle già tagliate', (
    tester,
  ) async {
    final c = await three(tester);
    await cut(tester, c, 50, 100);
    final bytes = png(70, 70, 5);
    final l = (await tester.runAsync(
      () => ImageLoader.decode(bytes, 'n.png'),
    ))!;
    c.addImages(PickedImages.single(l));
    expect(c.pageCount, 4);
    expect(c.pageIndex, 3, reason: 'si va alla prima aggiunta');
    expect(c.doc.width, 70);
    expect(c.pages[0].doc.height, 150, reason: 'il taglio resta');
    expect(c.imagesRoom, ImageLoader.maxImages - 4);
    c.dispose();
  });

  testWidgets('togliere una pagina rinumera le altre e tiene i tagli', (
    tester,
  ) async {
    final c = await three(tester);
    await cut(tester, c, 50, 100);
    c.goToPage(1);
    c.removeCurrentPage();
    expect(c.pageCount, 2);
    expect(c.images.map((f) => f.name), ['foto_0.png', 'foto_2.png']);
    expect([for (final p in c.pages) p.index], [0, 1]);
    expect(c.pageIndex, 1);
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    expect(c.doc.width, 90, reason: 'ora la pagina 2 è la terza foto');
    expect(c.pages[0].doc.height, 150);
    c.removeCurrentPage();
    expect(c.pageCount, 1);
    expect(c.canRemovePage, isFalse, reason: 'ne resta almeno una');
    c.removeCurrentPage();
    expect(c.pageCount, 1);
    c.dispose();
  });

  testWidgets('spostare una pagina cambia l\'ordine del salvataggio', (
    tester,
  ) async {
    final c = await three(tester);
    await cut(tester, c, 50, 100);
    expect(c.canMovePage(-1), isFalse);
    c.movePage(1);
    expect(c.pageIndex, 1, reason: 'si resta sulla pagina spostata');
    expect(c.images.map((f) => f.name), [
      'foto_1.png',
      'foto_0.png',
      'foto_2.png',
    ]);
    expect(c.doc.height, 150, reason: 'i tagli viaggiano con la pagina');
    expect([for (final p in c.pages) p.index], [0, 1, 2]);
    final files = (await tester.runAsync(c.buildImageExports))!;
    expect(img.decodePng(files[0].bytes)!.width, 200);
    expect(img.decodePng(files[1].bytes)!.height, 150);
    c.movePage(1);
    expect(c.pageIndex, 2);
    expect(c.canMovePage(1), isFalse);
    c.dispose();
  });

  testWidgets(
    'A e B su tutta la pagina: niente taglio, si propone di togliere la pagina',
    (tester) async {
      final c = await three(tester);
      c.selection = c.selection.withLines(
        CutOrientation.horizontal,
        const LinePair(0, 200),
      );
      expect(c.canCut, isFalse, reason: 'non resterebbe nulla');
      expect(c.selectsWholePage, isTrue);
      expect(c.canPressCut, isTrue);
      expect(c.canRemovePage, isTrue);
      c.selection = c.selection.withLines(
        CutOrientation.horizontal,
        const LinePair(10, 200),
      );
      expect(c.selectsWholePage, isFalse);
      expect(c.canCut, isTrue);
      c.dispose();
    },
  );
}
