import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:smashcrop/features/export/images_pdf.dart';

void main() {
  test('toglie EXIF e GPS senza toccare i pixel', () {
    final src = img.Image(width: 40, height: 30);
    for (final p in src) {
      p
        ..r = p.x * 6
        ..g = p.y * 8
        ..b = 90;
    }
    src.exif.imageIfd['Make'] = 'Telefono';
    src.exif.gpsIfd['GPSLatitude'] = 45.0;
    final jpeg = img.encodeJpg(src, quality: 90);
    expect(img.decodeJpgExif(jpeg)?.imageIfd['Make'], isNotNull);

    final clean = stripJpegMetadata(jpeg)!;
    expect(clean.length, lessThan(jpeg.length));
    final exif = img.decodeJpgExif(clean);
    expect(exif == null || exif.isEmpty, isTrue);
    final a = img.decodeJpg(jpeg)!, b = img.decodeJpg(clean)!;
    expect(b.width, a.width);
    expect(b.height, a.height);
    expect(
      b.getBytes(),
      orderedEquals(a.getBytes()),
      reason: 'i dati dell\'immagine sono copiati così come sono',
    );
  });

  test('una foto vera con orientamento EXIF resta leggibile', () {
    final jpeg = File('test/fixtures/ruotata_exif6.jpg').readAsBytesSync();
    final clean = stripJpegMetadata(Uint8List.fromList(jpeg));
    expect(clean, isNotNull);
    expect(img.decodeJpg(clean!), isNotNull);
  });

  test('un file che non è JPEG si rifiuta', () {
    expect(stripJpegMetadata(Uint8List.fromList([1, 2, 3, 4, 5])), isNull);
  });
}
