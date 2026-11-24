import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/pdf_processing/services/pdf_service.dart';

void main() {
  bool? scan(String f) => PdfSession.scanModifyPermission(
    File('test/fixtures/$f').readAsBytesSync(),
  );

  test('PDF non cifrato: nessuna restrizione da rispettare', () {
    expect(scan('libero.pdf'), isNull);
  });

  test('il proprietario vieta la modifica: va rispettato', () {
    expect(scan('solo_stampa.pdf'), isFalse);
  });

  test('il proprietario consente la modifica', () {
    expect(scan('modificabile.pdf'), isTrue);
  });

  test('PDF con password di apertura e permessi pieni', () {
    expect(scan('password.pdf'), isTrue);
  });
}
