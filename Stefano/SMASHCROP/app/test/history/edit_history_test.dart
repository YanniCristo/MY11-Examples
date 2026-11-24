import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/edit_history.dart';
import 'package:smashcrop/features/editor/domain/strip_document.dart';

CutOperation h(int a, int b, int len) => CutOperation(
  orientation: CutOrientation.horizontal,
  start: a,
  end: b,
  lengthBefore: len,
);

void main() {
  test('undo e redo ripristinano gli stati', () {
    final hist = EditHistory(StripDocument.original(100, 200));
    hist.push(h(10, 30, 200));
    hist.push(h(0, 50, 180));
    expect(hist.current.height, 130);
    expect(hist.undo(), isTrue);
    expect(hist.current.height, 180);
    expect(hist.undo(), isTrue);
    expect(hist.current.height, 200);
    expect(hist.canUndo, isFalse);
    expect(hist.redo(), isTrue);
    expect(hist.redo(), isTrue);
    expect(hist.current.height, 130);
    expect(hist.canRedo, isFalse);
  });

  test('un nuovo taglio dopo Undo elimina il ramo di Redo', () {
    final hist = EditHistory(StripDocument.original(100, 200));
    hist.push(h(10, 30, 200));
    hist.push(h(0, 50, 180));
    hist.undo();
    hist.push(h(100, 120, 180));
    expect(hist.length, 2);
    expect(hist.canRedo, isFalse);
    expect(hist.current.height, 160);
  });

  test("l'originale non cambia mai", () {
    final orig = StripDocument.original(100, 200);
    final hist = EditHistory(orig);
    hist.push(h(10, 30, 200));
    expect(hist.original.height, 200);
    expect(identical(hist.original, orig), isTrue);
  });
}
