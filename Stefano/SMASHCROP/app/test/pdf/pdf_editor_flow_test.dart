import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashcrop/features/editor/application/editor_controller.dart';
import 'package:smashcrop/features/editor/application/editor_page.dart';
import 'package:smashcrop/features/editor/application/saved_work.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/selection_state.dart';
import 'package:smashcrop/features/pdf_processing/domain/page_layout.dart';
import 'package:smashcrop/features/settings/preferences.dart';

Future<ui.Image> blank(int w, int h) async {
  final px = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
  final buf = await ui.ImmutableBuffer.fromUint8List(px);
  final desc = ui.ImageDescriptor.raw(
    buf,
    width: w,
    height: h,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  return (await (await desc.instantiateCodec()).getNextFrame()).image;
}

void main() {
  late AppPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await AppPreferences.load();
  });

  /// Quattro pagine di formati diversi: A4 verticale, A4 orizzontale,
  /// scontrino lungo, Letter.
  Future<EditorController> fourPages(WidgetTester tester) async {
    const sizes = [
      (595.0, 842.0),
      (842.0, 595.0),
      (226.0, 1400.0),
      (612.0, 792.0),
    ];
    final pages = <EditorPage>[];
    for (var i = 0; i < sizes.length; i++) {
      final (w, h) = sizes[i];
      const k = 1.0; // 1 pixel per punto: basta per la geometria
      final img = (await tester.runAsync(
        () => blank((w * k).round(), (h * k).round()),
      ))!;
      pages.add(
        EditorPage(
          index: i,
          widthPx: (w * k).round(),
          heightPx: (h * k).round(),
          pxPerPoint: k,
          originalPointSize: ui.Size(w, h),
          image: img,
        ),
      );
    }
    return EditorController.pdfPages(pages: pages, preferences: prefs)
      ..setViewportSize(const ui.Size(360, 480))
      ..smashAvailable = true;
  }

  void cut(EditorController c, CutOrientation o, double a, double b) {
    if (c.selection.mode != o) c.tapOrientation(o);
    c.selection = c.selection.withLines(o, LinePair(a, b));
    expect(c.removePortion(), isTrue);
    c.tick(const Duration(seconds: 10));
  }

  testWidgets('primo taglio: si apre il pannello, la selezione aspetta', (
    tester,
  ) async {
    final c = await fourPages(tester);
    c.goToPage(1);
    cut(c, CutOrientation.horizontal, 100, 300);
    expect(c.layoutPanelOpen, isTrue);
    expect(
      c.previewLayout,
      const PageLayout(PdfLayoutMode.top),
      reason: 'suggerimento iniziale: In alto',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      c.selectionVisible,
      isFalse,
      reason: 'niente selezione sotto il pannello',
    );

    c.previewLayoutMode(PdfLayoutMode.centered);
    expect(
      c.frame.contentOffset.dy,
      closeTo(100, .001),
      reason: 'anteprima dal vivo',
    );
    c.applyLayout();
    expect(c.layoutPanelOpen, isFalse);
    expect(c.selectionVisible, isTrue);
    expect(c.page.history.layout, const PageLayout(PdfLayoutMode.centered));

    // il secondo taglio non riapre il pannello
    cut(c, CutOrientation.horizontal, 10, 60);
    expect(c.layoutPanelOpen, isFalse);
    expect(
      c.frame.size,
      const ui.Size(842, 595),
      reason: 'il foglio resta quello originale',
    );
    expect(c.doc.height, 595 - 200 - 50);
    c.dispose();
  });

  testWidgets('ogni pagina tiene la propria impaginazione', (tester) async {
    final c = await fourPages(tester);
    final modes = [
      PdfLayoutMode.centered,
      PdfLayoutMode.top,
      PdfLayoutMode.shrink,
    ];
    for (var i = 0; i < 3; i++) {
      c.goToPage(i);
      cut(c, CutOrientation.horizontal, 50, 150);
      c.previewLayoutMode(modes[i]);
      c.applyLayout();
    }
    c.goToPage(3);
    cut(c, CutOrientation.horizontal, 50, 150);
    c.previewLayoutMode(PdfLayoutMode.custom);
    c.applyLayout();
    expect(c.positioning, isTrue);
    c.gestureStart(const ui.Offset(180, 200));
    c.gestureUpdate(const ui.Offset(180, 260), 1);
    final moved = c.positionOffset;
    expect(moved.dy, greaterThan(0));
    final sizeBefore = c.frame.contentSize;
    c.confirmPosition();
    expect(
      c.frame.contentSize,
      sizeBefore,
      reason: 'la posizione non cambia la misura',
    );

    for (var i = 0; i < 3; i++) {
      expect(c.pages[i].history.layout, PageLayout(modes[i]));
    }
    expect(c.pages[3].history.layout!.mode, PdfLayoutMode.custom);
    // Riduci pagina: foglio più corto dello stesso numero di pixel tagliati
    expect(c.pages[2].frame(PdfLayoutMode.top).size, const ui.Size(226, 1300));

    // Undo della posizione personalizzata, poi Redo
    c.undo();
    expect(c.page.history.layout, isNull);
    c.redo();
    expect(c.page.history.layout!.offset, moved);
    c.dispose();
  });

  testWidgets('Annulla esce dal posizionamento senza applicare', (
    tester,
  ) async {
    final c = await fourPages(tester);
    cut(c, CutOrientation.horizontal, 100, 200);
    c.applyLayout();
    c.startPositioning();
    c.gestureStart(const ui.Offset(100, 100));
    c.gestureUpdate(const ui.Offset(100, 180), 1);
    c.cancelPositioning();
    expect(c.positioning, isFalse);
    expect(c.page.history.layout, const PageLayout(PdfLayoutMode.top));
    c.dispose();
  });

  testWidgets('layout per le prossime pagine: le precedenti non cambiano', (
    tester,
  ) async {
    final c = await fourPages(tester);
    // pagina 1: In alto, senza casella
    cut(c, CutOrientation.horizontal, 100, 200);
    expect(c.layoutPanelOpen, isTrue);
    c.previewLayoutMode(PdfLayoutMode.top);
    c.applyLayout();
    // pagina 2: Riduci pagina, con la casella spuntata
    c.goToPage(1);
    cut(c, CutOrientation.horizontal, 100, 200);
    expect(c.layoutForNext, isFalse);
    c.previewLayoutMode(PdfLayoutMode.shrink);
    c.setLayoutForNext(true);
    c.applyLayout();
    expect(
      c.pages[0].history.layout,
      const PageLayout(PdfLayoutMode.top),
      reason: 'la pagina già fatta resta come era',
    );
    // pagina 3: il pannello non si riapre, prende Riduci pagina da sola
    c.goToPage(2);
    cut(c, CutOrientation.vertical, 50, 100);
    expect(c.layoutPanelOpen, isFalse);
    expect(c.pages[2].history.layout, const PageLayout(PdfLayoutMode.shrink));
    // dal pulsante Layout PDF si toglie la casella: si torna a chiedere
    c.openLayoutPanel();
    expect(c.layoutForNext, isTrue);
    c.setLayoutForNext(false);
    c.applyLayout();
    c.goToPage(3);
    cut(c, CutOrientation.horizontal, 100, 200);
    expect(c.layoutPanelOpen, isTrue);
    c.dismissLayoutPanel();
    expect(c.pages[1].history.layout, const PageLayout(PdfLayoutMode.shrink));
    c.dispose();
  });

  testWidgets(
    'Personalizza come layout per le prossime: il pannello si riapre',
    (tester) async {
      final c = await fourPages(tester);
      cut(c, CutOrientation.horizontal, 100, 200);
      c.previewLayoutMode(PdfLayoutMode.custom);
      c.setLayoutForNext(true);
      c.applyLayout();
      expect(c.positioning, isTrue);
      c.confirmPosition();
      c.goToPage(1);
      cut(c, CutOrientation.horizontal, 100, 200);
      expect(c.layoutPanelOpen, isTrue);
      expect(c.previewLayout!.mode, PdfLayoutMode.custom);
      expect(c.layoutForNext, isTrue);
      c.dispose();
    },
  );

  testWidgets('cambiare pagina non perde i tagli', (tester) async {
    final c = await fourPages(tester);
    cut(c, CutOrientation.horizontal, 100, 300);
    c.applyLayout();
    c.goToPage(2);
    c.goToPage(0);
    expect(c.doc.height, 842 - 200);
    expect(c.pages[2].history.hasCuts, isFalse);
    c.dispose();
  });

  testWidgets('togliere una pagina del PDF tiene il numero originale', (
    tester,
  ) async {
    final c = await fourPages(tester);
    c.goToPage(1);
    expect(c.canRemovePage, isTrue);
    c.removeCurrentPage();
    expect(c.pageCount, 3);
    expect([for (final p in c.pages) p.index], [0, 2, 3]);
    expect(c.removedPdfPages, [1]);
    expect(c.pageIndex, 1);
    expect(c.page.index, 2, reason: 'ora si vede la pagina 3 originale');
    c.removeCurrentPage();
    c.removeCurrentPage();
    expect(c.pageCount, 1);
    expect(c.canRemovePage, isFalse, reason: 'ne resta sempre una');
    expect(c.removedPdfPages, [1, 2, 3]);
  });

  testWidgets('le pagine tolte si salvano e si ripristinano', (tester) async {
    final c = await fourPages(tester);
    c.goToPage(2);
    c.removeCurrentPage();
    final w = SavedWork.capture(
      isPdf: true,
      name: 'a.pdf',
      size: 10,
      pageIndex: c.pageIndex,
      pages: c.pages,
      removed: c.removedPdfPages,
    )!;
    final back = SavedWork.decode(w.encode())!;
    expect(back.removed, [2]);
    expect(back.cutCount, 0);

    final fresh = await fourPages(tester);
    fresh.restoreWork(back);
    expect(fresh.pageCount, 3);
    expect([for (final p in fresh.pages) p.index], [0, 1, 3]);
  });
}
