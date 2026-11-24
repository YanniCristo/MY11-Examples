import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/application/editor_page.dart';
import 'package:smashcrop/features/editor/application/saved_work.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/pdf_processing/domain/page_layout.dart';

EditorPage page(int i, int w, int h) =>
    EditorPage(index: i, widthPx: w, heightPx: h);

void main() {
  test('il lavoro salvato si rilegge e si rifà uguale', () {
    final pages = [page(0, 100, 200), page(1, 100, 200), page(2, 100, 200)];
    pages[0].history
      ..push(
        const CutOperation(
          orientation: CutOrientation.horizontal,
          start: 20,
          end: 60,
          lengthBefore: 200,
        ),
      )
      ..pushLayout(const PageLayout(PdfLayoutMode.custom, Offset(0, 12)));
    pages[2].history.push(
      const CutOperation(
        orientation: CutOrientation.vertical,
        start: 10,
        end: 30,
        lengthBefore: 100,
      ),
    );
    final w = SavedWork.capture(
      isPdf: true,
      name: 'Fattura.pdf',
      size: 12345,
      pageIndex: 2,
      pages: pages,
      nextPagesLayout: PdfLayoutMode.shrink,
    )!;
    expect(w.cutCount, 2);
    final back = SavedWork.decode(w.encode())!;
    expect(back.matches(isPdf: true, name: 'Fattura.pdf', size: 12345), isTrue);
    expect(back.matches(isPdf: true, name: 'Fattura.pdf', size: 1), isFalse);
    expect(back.pageIndex, 2);
    expect(back.nextPagesLayout, PdfLayoutMode.shrink);

    // stesso file, stessa risoluzione
    final again = [page(0, 100, 200), page(1, 100, 200), page(2, 100, 200)];
    expect(back.replayOn(again), 2);
    expect(again[0].doc.height, 160);
    expect(
      again[0].history.layout,
      const PageLayout(PdfLayoutMode.custom, Offset(0, 12)),
    );
    expect(again[1].history.hasCuts, isFalse);
    expect(again[2].doc.width, 80);

    // altro dispositivo: risoluzione doppia, i tagli si riportano
    final big = [page(0, 200, 400), page(1, 200, 400), page(2, 200, 400)];
    back.replayOn(big);
    expect(big[0].doc.height, 320);
    expect(big[0].history.layout!.offset, const Offset(0, 24));
    expect(big[2].doc.width, 160);
  });

  test('nessun taglio: niente da salvare; dati rovinati: ignorati', () {
    expect(
      SavedWork.capture(
        isPdf: false,
        name: 'a.jpg',
        size: 1,
        pageIndex: 0,
        pages: [page(0, 10, 10)],
      ),
      isNull,
    );
    expect(SavedWork.decode('{non json'), isNull);
    expect(SavedWork.decode(null), isNull);
  });
}
