import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/strip_document.dart';
import 'package:smashcrop/features/export/image_encoder.dart';
import 'package:smashcrop/features/image_processing/services/image_loader.dart';

Uint8List fixture(String f) => File('test/fixtures/$f').readAsBytesSync();

StripDocument cut(int w, int h, CutOrientation o, int a, int b) =>
    StripDocument.original(w, h).apply(
      CutOperation(
        orientation: o,
        start: a,
        end: b,
        lengthBefore: o == CutOrientation.horizontal ? h : w,
      ),
    );

void main() {
  test(
    "PNG: pixel identici all'originale, alpha e profilo colore conservati",
    () {
      final bytes = fixture('rumore_icc.png');
      final doc = cut(50, 80, CutOrientation.horizontal, 20, 45);
      final out = encodeImageJob(
        ImageEncodeJob(
          format: OutputFormat.png,
          srcW: 50,
          srcH: 80,
          outW: doc.width,
          outH: doc.height,
          tiles: doc.tiles(),
          original: bytes,
        ),
      )!;
      final src = img.decodePng(bytes)!;
      final res = img.decodePng(out)!;
      expect(res.width, 50);
      expect(res.height, 55);
      expect(res.iccProfile, isNotNull);
      expect(res.iccProfile!.decompressed(), src.iccProfile!.decompressed());
      for (var y = 0; y < res.height; y++) {
        final sy = y < 20 ? y : y + 25;
        for (var x = 0; x < res.width; x++) {
          final a = res.getPixel(x, y), b = src.getPixel(x, sy);
          expect(
            [a.r, a.g, a.b, a.a],
            [b.r, b.g, b.b, b.a],
            reason: 'pixel $x,$y',
          );
        }
      }
    },
  );

  test(
    'JPEG: orientamento EXIF rispettato, qualità massima 4:4:4, niente EXIF',
    () {
      final bytes = fixture('ruotata_exif6.jpg');
      // sul telefono appare ruotata: 40×60
      final doc = cut(40, 60, CutOrientation.horizontal, 10, 30);
      final out = encodeImageJob(
        ImageEncodeJob(
          format: OutputFormat.jpeg,
          srcW: 40,
          srcH: 60,
          outW: doc.width,
          outH: doc.height,
          tiles: doc.tiles(),
          original: bytes,
        ),
      )!;
      final res = img.decodeJpg(out)!;
      expect(res.width, 40);
      expect(res.height, 40);
      expect(res.exif.imageIfd.hasOrientation, isFalse);
      expect(res.iccProfile, isNotNull);
      final ref = img.bakeOrientation(img.decodeJpg(bytes)!);
      var maxDiff = 0;
      for (var y = 0; y < 40; y++) {
        final sy = y < 10 ? y : y + 20;
        for (var x = 0; x < 40; x++) {
          final a = res.getPixel(x, y), b = ref.getPixel(x, sy);
          for (final d in [a.r - b.r, a.g - b.g, a.b - b.b]) {
            if (d.abs() > maxDiff) maxDiff = d.abs().toInt();
          }
        }
      }
      expect(
        maxDiff,
        lessThanOrEqualTo(4),
        reason: 'differenza massima per canale: $maxDiff',
      );
    },
  );

  test('formato non leggibile qui: si usano i pixel del sistema', () {
    final rgba = Uint8List(4 * 10 * 10)..fillRange(0, 400, 128);
    final doc = cut(10, 10, CutOrientation.vertical, 2, 5);
    final heicLike = Uint8List.fromList([
      0,
      0,
      0,
      24,
      102,
      116,
      121,
      112,
      104,
      101,
      105,
      99,
    ]);
    final job = ImageEncodeJob(
      format: OutputFormat.jpeg,
      srcW: 10,
      srcH: 10,
      outW: doc.width,
      outH: doc.height,
      tiles: doc.tiles(),
      original: heicLike,
    );
    expect(
      encodeImageJob(job),
      isNull,
      reason: 'senza pixel di riserva non si inventa nulla',
    );
    final out = encodeImageJob(
      ImageEncodeJob(
        format: OutputFormat.jpeg,
        srcW: 10,
        srcH: 10,
        outW: doc.width,
        outH: doc.height,
        tiles: doc.tiles(),
        rgba: rgba,
      ),
    )!;
    expect(img.decodeJpg(out)!.width, 7);
  });

  for (final f in [
    OutputFormat.webp,
    OutputFormat.gif,
    OutputFormat.bmp,
    OutputFormat.tiff,
  ]) {
    test('${f.name}: stesso formato in uscita, pixel identici', () {
      // 64 colori + trasparenza: va bene anche per la GIF
      final src = img.Image(width: 30, height: 20, numChannels: 4);
      for (final p in src) {
        final t = (p.x * 7 + p.y * 3) % 64;
        p.setRgba(
          (t & 3) * 85,
          ((t >> 2) & 3) * 85,
          ((t >> 4) & 3) * 85,
          p.x == 0 ? 0 : 255,
        );
      }
      final original = encodeAs(f, src);
      final doc = cut(30, 20, CutOrientation.vertical, 5, 12);
      final out = encodeImageJob(
        ImageEncodeJob(
          format: f,
          srcW: 30,
          srcH: 20,
          outW: doc.width,
          outH: doc.height,
          tiles: doc.tiles(),
          original: original,
        ),
      )!;
      expect(
        img.findFormatForData(out).name,
        anyOf(f.name, f == OutputFormat.tiff ? 'tiff' : f.name),
      );
      final ref = img.decodeImage(original)!;
      final res = img.decodeImage(out)!;
      expect(res.width, 23);
      for (var y = 0; y < 20; y++) {
        for (var x = 0; x < 23; x++) {
          final a = res.getPixel(x, y), b = ref.getPixel(x < 5 ? x : x + 7, y);
          if (b.a == 0) {
            expect(a.a, 0);
          } else {
            expect(
              [a.r, a.g, a.b, a.a],
              [b.r, b.g, b.b, b.a],
              reason: '${f.name} pixel $x,$y',
            );
          }
        }
      }
    });
  }
}
