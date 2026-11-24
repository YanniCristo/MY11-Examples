import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/edit_history.dart';
import 'package:smashcrop/features/editor/domain/strip_document.dart';
import 'package:smashcrop/features/pdf_processing/domain/page_layout.dart';

void main() {
  const page = Size(1000, 1400);

  group('quattro impaginazioni', () {
    test(
      'Centrato: foglio originale, contenuto al centro, misura invariata',
      () {
        final f = PageFrame.compute(
          original: page,
          content: const Size(1000, 1000),
          layout: const PageLayout(PdfLayoutMode.centered),
        );
        expect(f.size, page);
        expect(f.contentSize, const Size(1000, 1000));
        expect(f.contentOffset, const Offset(0, 200));
      },
    );

    test('Centrato dopo tagli in entrambe le direzioni', () {
      final f = PageFrame.compute(
        original: page,
        content: const Size(800, 1000),
        layout: const PageLayout(PdfLayoutMode.centered),
      );
      expect(f.contentOffset, const Offset(100, 200));
    });

    test('In alto: in alto a sinistra, spazio libero sotto e a destra', () {
      final f = PageFrame.compute(
        original: page,
        content: const Size(800, 1000),
        layout: const PageLayout(PdfLayoutMode.top),
      );
      expect(f.size, page);
      expect(f.contentOffset, Offset.zero);
    });

    test('Riduci pagina: il foglio diventa grande come il contenuto', () {
      final f = PageFrame.compute(
        original: page,
        content: const Size(800, 1000),
        layout: const PageLayout(PdfLayoutMode.shrink),
      );
      expect(f.size, const Size(800, 1000));
      expect(f.contentSize, const Size(800, 1000));
      expect(f.contentOffset, Offset.zero);
    });

    test(
      'Personalizza: si sposta senza uscire dal foglio e senza cambiare misura',
      () {
        final f = PageFrame.compute(
          original: page,
          content: const Size(800, 1000),
          layout: const PageLayout(PdfLayoutMode.custom, Offset(150, 9999)),
        );
        expect(f.size, page);
        expect(f.contentSize, const Size(800, 1000));
        expect(f.contentOffset, const Offset(150, 400));
        final g = PageFrame.compute(
          original: page,
          content: const Size(800, 1000),
          layout: const PageLayout(PdfLayoutMode.custom, Offset(-50, -50)),
        );
        expect(g.contentOffset, Offset.zero);
      },
    );

    test('senza tagli foglio e contenuto coincidono', () {
      final f = PageFrame.compute(original: page, content: page, layout: null);
      expect(f.size, page);
      expect(f.contentOffset, Offset.zero);
    });

    test("esattamente quattro modalità, in quest'ordine", () {
      expect(PdfLayoutMode.values.map((m) => m.label).toList(), [
        'Centrato',
        'In alto',
        'Riduci pagina',
        'Personalizza posizione',
      ]);
    });
  });

  group('cronologia con impaginazione', () {
    test("l'impaginazione si annulla e ripristina come i tagli", () {
      final h = EditHistory(StripDocument.original(1000, 1400));
      h.push(
        const CutOperation(
          orientation: CutOrientation.horizontal,
          start: 100,
          end: 500,
          lengthBefore: 1400,
        ),
      );
      h.pushLayout(const PageLayout(PdfLayoutMode.centered));
      h.pushLayout(const PageLayout(PdfLayoutMode.custom, Offset(0, 120)));
      expect(h.layout, const PageLayout(PdfLayoutMode.custom, Offset(0, 120)));
      h.undo();
      expect(h.layout, const PageLayout(PdfLayoutMode.centered));
      h.undo();
      expect(h.layout, isNull);
      expect(h.current.height, 1000, reason: 'il taglio resta');
      h.redo();
      expect(h.layout, const PageLayout(PdfLayoutMode.centered));
    });

    test(
      'i tagli successivi lavorano sul contenuto, non sui margini bianchi',
      () {
        final h = EditHistory(StripDocument.original(1000, 1400));
        h.push(
          const CutOperation(
            orientation: CutOrientation.horizontal,
            start: 0,
            end: 400,
            lengthBefore: 1400,
          ),
        );
        h.pushLayout(const PageLayout(PdfLayoutMode.centered));
        // il contenuto è alto 1000: il secondo taglio si riferisce a quello
        expect(h.current.height, 1000);
        h.push(
          const CutOperation(
            orientation: CutOrientation.horizontal,
            start: 900,
            end: 1000,
            lengthBefore: 1000,
          ),
        );
        expect(h.current.height, 900);
        expect(h.current.rows.originalIndex(0), 400);
      },
    );
  });
}
