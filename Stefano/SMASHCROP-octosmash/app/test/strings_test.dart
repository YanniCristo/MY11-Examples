import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/app/strings.dart';

void main() {
  test('ogni lingua ha tutti i testi, Undo e Redo restano uguali', () {
    for (final l in AppLang.values) {
      S.current.value = l;
      for (final t in [
        S.homeTitle,
        S.loadImage,
        S.loadPdf,
        S.removePortion,
        S.layoutForNext,
        S.rasterNote,
        S.largeBody(160),
        S.resumeBody('a.pdf', 2),
        S.pageOf(2, 8),
      ]) {
        expect(t.trim(), isNotEmpty, reason: '${l.name}: testo vuoto');
      }
      expect(S.undo, 'Undo');
      expect(S.redo, 'Redo');
    }
    S.current.value = AppLang.fr;
    expect(S.resumeBody('a.pdf', 1), 'a.pdf · 1 découpe');
    expect(S.pageOf(2, 8), 'Page 2 sur 8');
    S.current.value = AppLang.en;
  });

  test('codici lingua: sconosciuto = nessuna scelta', () {
    expect(AppLang.fromCode('pt'), AppLang.pt);
    expect(AppLang.fromCode('ja'), isNull);
  });
}
