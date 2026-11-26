import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/strip_document.dart';

void main() {
  test('i tagli si riportano in proporzione su una risoluzione più alta', () {
    // schermo 100×200, salvataggio 250×500 (×2,5)
    final d = StripDocument.original(100, 200)
        .apply(
          const CutOperation(
            orientation: CutOrientation.horizontal,
            start: 40,
            end: 80,
            lengthBefore: 200,
          ),
        )
        .apply(
          const CutOperation(
            orientation: CutOrientation.vertical,
            start: 10,
            end: 30,
            lengthBefore: 100,
          ),
        );
    final e = d.rescaled(250, 500);
    expect(e.rows.runs.map((r) => [r.start, r.end]), [
      [0, 100],
      [200, 500],
    ]);
    expect(e.cols.runs.map((r) => [r.start, r.end]), [
      [0, 25],
      [75, 250],
    ]);
    expect(e.height, 400);
    expect(e.width, 200);
    expect(d.rescaled(100, 200), isA<StripDocument>());
    expect(d.rescaled(100, 200).height, d.height);
  });
}
