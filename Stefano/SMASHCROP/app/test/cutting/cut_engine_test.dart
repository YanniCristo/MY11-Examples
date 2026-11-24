import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/domain/cut_operation.dart';
import 'package:smashcrop/features/editor/domain/strip_document.dart';
import 'package:smashcrop/features/image_processing/domain/raster_image.dart';

/// Immagine di prova: ogni pixel codifica la propria posizione originale,
/// così si verifica esattamente quale pixel finisce dove.
RasterImage coded(int w, int h) {
  final b = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      b[i] = x & 0xff;
      b[i + 1] = y & 0xff;
      b[i + 2] = (x >> 8) | ((y >> 8) << 4);
      b[i + 3] = 255 - ((x + y) % 7); // alpha variabile: deve restare intatto
    }
  }
  return RasterImage(w, h, b);
}

({int x, int y}) origin(RasterImage im, int x, int y) {
  final i = (y * im.width + x) * 4;
  final hi = im.rgba[i + 2];
  return (x: im.rgba[i] | ((hi & 0x0f) << 8), y: im.rgba[i + 1] | ((hi >> 4) << 8));
}

CutOperation op(CutOrientation o, double a, double b, int len) =>
    CutOperation.fromLines(orientation: o, a: a, b: b, length: len)!;

void main() {
  group('taglio orizzontale', () {
    test('elimina le righe e ricongiunge sopra e sotto', () {
      final im = coded(40, 100);
      final out = im.cut(op(CutOrientation.horizontal, 30, 50, 100));
      expect(out.width, 40);
      expect(out.height, 80);
      for (var y = 0; y < 80; y++) {
        for (var x = 0; x < 40; x++) {
          final o = origin(out, x, y);
          expect(o.x, x);
          expect(o.y, y < 30 ? y : y + 20, reason: 'riga $y');
        }
      }
    });

    test('A e B invertite danno lo stesso risultato', () {
      final im = coded(20, 60);
      final a = im.cut(op(CutOrientation.horizontal, 10, 25, 60));
      final b = im.cut(op(CutOrientation.horizontal, 25, 10, 60));
      expect(a.rgba, b.rgba);
    });

    test('alpha e valori dei pixel restano identici', () {
      final im = coded(16, 16);
      final out = im.cut(op(CutOrientation.horizontal, 4, 8, 16));
      for (var y = 0; y < out.height; y++) {
        for (var x = 0; x < out.width; x++) {
          final sy = y < 4 ? y : y + 4;
          expect(out.pixel(x, y), im.pixel(x, sy));
        }
      }
    });
  });

  group('taglio verticale', () {
    test('elimina le colonne e ricongiunge sinistra e destra', () {
      final im = coded(300, 30);
      final out = im.cut(op(CutOrientation.vertical, 280, 100, 300));
      expect(out.width, 120);
      expect(out.height, 30);
      for (var y = 0; y < 30; y++) {
        for (var x = 0; x < 120; x++) {
          final o = origin(out, x, y);
          expect(o.x, x < 100 ? x : x + 180);
          expect(o.y, y);
        }
      }
    });
  });

  group('validità', () {
    test('fascia di ampiezza nulla rifiutata', () {
      expect(
          CutOperation.fromLines(
              orientation: CutOrientation.horizontal, a: 40, b: 40.2, length: 100),
          isNull);
    });

    test('taglio che elimina tutto rifiutato', () {
      expect(
          CutOperation.fromLines(
              orientation: CutOrientation.vertical, a: 0, b: 100, length: 100),
          isNull);
    });

    test('coordinate fuori dal documento vengono limitate', () {
      final c = CutOperation.fromLines(
          orientation: CutOrientation.horizontal, a: -20, b: 30, length: 100)!;
      expect(c.start, 0);
      expect(c.end, 30);
    });

    test('taglio non coerente con le dimensioni rifiutato dal motore', () {
      final im = coded(10, 10);
      expect(
          () => im.cut(const CutOperation(
              orientation: CutOrientation.horizontal, start: 2, end: 4, lengthBefore: 12)),
          throwsStateError);
    });
  });

  group('tagli consecutivi', () {
    test('runs e motore pixel danno lo stesso risultato su sequenze casuali', () {
      final rnd = Random(42);
      for (var round = 0; round < 40; round++) {
        final w = 5 + rnd.nextInt(60);
        final h = 5 + rnd.nextInt(60);
        final original = coded(w, h);
        var raster = original;
        var doc = StripDocument.original(w, h);
        for (var i = 0; i < 6; i++) {
          final o = rnd.nextBool() ? CutOrientation.horizontal : CutOrientation.vertical;
          final len = doc.lengthFor(o);
          if (len < 3) continue;
          final a = rnd.nextInt(len).toDouble();
          final b = rnd.nextInt(len).toDouble();
          final c = CutOperation.fromLines(orientation: o, a: a, b: b, length: len);
          if (c == null) continue;
          raster = raster.cut(c);
          doc = doc.apply(c);
          expect(doc.width, raster.width);
          expect(doc.height, raster.height);
        }
        final composed = RasterImage.compose(original, doc);
        expect(composed.rgba, raster.rgba, reason: 'round $round');
      }
    });

    test('dimensioni corrette dopo più tagli misti', () {
      var doc = StripDocument.original(1080, 2400);
      doc = doc.apply(op(CutOrientation.horizontal, 300, 700, 2400));
      doc = doc.apply(op(CutOrientation.horizontal, 100, 200, 2000));
      doc = doc.apply(op(CutOrientation.vertical, 500, 600, 1080));
      expect(doc.width, 980);
      expect(doc.height, 1900);
      // riga 150 attuale = riga 250 dell'originale (100 righe tolte prima)
      expect(doc.rows.originalIndex(150), 250);
      // riga 250 attuale: dopo il secondo taglio diventa 350, poi oltre il
      // primo taglio (300..700) diventa 750
      expect(doc.rows.originalIndex(250), 750);
      expect(doc.cols.originalIndex(550), 650);
    });
  });
}
