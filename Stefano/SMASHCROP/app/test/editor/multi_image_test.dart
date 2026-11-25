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
    expect(files.single.fileName.contains('_01'), isFalse);
    c.dispose();
  });
}
