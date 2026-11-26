import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smashcrop/features/editor/domain/edit_history.dart';
import 'package:smashcrop/features/editor/domain/strip_document.dart';
import 'package:smashcrop/features/image_processing/domain/raster_image.dart';
import 'package:smashcrop/features/octo/domain/ink_fill.dart';
import 'package:smashcrop/features/octo/domain/ink_math.dart';
import 'package:smashcrop/features/octo/domain/octo_rect.dart';

void main() {
  test('rettangolo ruotato: dentro e fuori', () {
    const f = InkFill(
      cx: 50,
      cy: 50,
      w: 40,
      h: 10,
      angle: math.pi / 2,
      color: InkFill.black,
    );
    expect(f.contains(50, 65), isTrue); // ruotato di 90°: ora è alto
    expect(f.contains(65, 50), isFalse);
  });

  test("l'inchiostro colora solo dentro il rettangolo", () {
    final img = RasterImage(
      20,
      20,
      Uint8List(20 * 20 * 4)..fillRange(0, 1600, 200),
    );
    applyInkFills(img, [
      const InkFill(
        cx: 10,
        cy: 10,
        w: 6,
        h: 4,
        angle: 0,
        color: InkFill.black,
      ).toList(),
    ]);
    int px(int x, int y) => img.rgba[(y * 20 + x) * 4];
    expect(px(10, 10), 0);
    expect(px(7, 8), 0);
    expect(px(6, 10), 200); // appena fuori
    expect(px(10, 13), 200);
  });

  test('angoli: ridimensiona tenendo fermo l\'opposto, ruota, sposta', () {
    final r = OctoRect(
      center: const Offset(100, 100),
      w: 40,
      h: 20,
      color: InkFill.whiteInk,
    );
    final fixed = r.corner(2);
    r.resizeFrom(0, const Offset(60, 70));
    expect(r.corner(2).dx, closeTo(fixed.dx, 1e-6));
    expect(r.corner(2).dy, closeTo(fixed.dy, 1e-6));
    expect(r.w, closeTo(60, 1e-6));
    expect(r.h, closeTo(40, 1e-6));
    r.rotateBy(1);
    expect(r.degrees, 1);
    r.rotateBy(-1);
    expect(r.degrees, 0);
    r.move(const Offset(5, 5));
    expect(r.center, const Offset(95, 95));
  });

  test('la cronologia tiene gli inchiostri e li annulla', () {
    final h = EditHistory(StripDocument.original(100, 100));
    h.pushFills([
      const InkFill(
        cx: 1,
        cy: 1,
        w: 2,
        h: 2,
        angle: 0,
        color: InkFill.whiteInk,
      ),
    ]);
    expect(h.hasFills, isTrue);
    expect(h.fills.length, 1);
    h.undo();
    expect(h.fills, isEmpty);
    h.redo();
    expect(h.fills.single.white, isTrue);
  });

  test('litri e contenitori', () {
    expect(InkMath.litres(250000), 1);
    expect(InkMath.nextGoal(1), 0);
    expect(InkMath.nextGoal(10), 1);
    expect(InkMath.progress(2.5), closeTo(.5, 1e-9));
    expect(InkMath.nextGoal(5000), isNull);
  });

  test('inchiostro colorato e vecchi salvataggi', () {
    final img = RasterImage(4, 4, Uint8List(64));
    applyInkFills(img, [
      const InkFill(
        cx: 2,
        cy: 2,
        w: 4,
        h: 4,
        angle: 0,
        color: 0xFF336699,
      ).toList(),
    ]);
    expect(img.rgba.sublist(0, 4), [0x33, 0x66, 0x99, 255]);
    expect(InkFill.fromList([0, 0, 1, 1, 0, 1]).white, isTrue);
    expect(InkFill.fromList([0, 0, 1, 1, 0, 0]).color, InkFill.black);
  });

  test('la rotazione col dito va a gradi interi esatti', () {
    final r = OctoRect(
      center: const Offset(0, 0),
      w: 40,
      h: 20,
      color: InkFill.black,
    );
    // punto che darebbe circa 89,6° rispetto all'angolo in alto a destra
    final base = math.atan2(-10, 20);
    final a = base + 89.6 * math.pi / 180;
    r.rotateTo(Offset(math.cos(a) * 50, math.sin(a) * 50));
    expect(r.degrees, 90);
    expect(r.angle, closeTo(math.pi / 2, 1e-12));
  });
}
