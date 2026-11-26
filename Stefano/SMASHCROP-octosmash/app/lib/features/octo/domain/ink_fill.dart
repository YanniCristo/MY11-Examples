import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect;

import '../../image_processing/domain/raster_image.dart';

/// Un rettangolo d'inchiostro già spruzzato da OctoSmash, in pixel
/// dell'**originale** della pagina (così segue i tagli fatti dopo, come il
/// resto dell'immagine). Può essere ruotato.
class InkFill {
  const InkFill({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.angle,
    required this.color,
  });

  /// Centro, in pixel dell'originale.
  final double cx, cy;

  /// Larghezza e altezza (pixel), prima della rotazione.
  final double w, h;

  /// Rotazione in radianti (senso orario sullo schermo).
  final double angle;

  /// Colore dell'inchiostro (ARGB, sempre opaco).
  final int color;

  static const int black = 0xFF000000, whiteInk = 0xFFFFFFFF;

  bool get white => color == whiteInk;

  /// I quattro angoli (in alto a sinistra, in alto a destra, in basso a
  /// destra, in basso a sinistra), già ruotati.
  List<Offset> get corners {
    final c = math.cos(angle), s = math.sin(angle);
    Offset p(double x, double y) =>
        Offset(cx + x * c - y * s, cy + x * s + y * c);
    final hw = w / 2, hh = h / 2;
    return [p(-hw, -hh), p(hw, -hh), p(hw, hh), p(-hw, hh)];
  }

  Rect get bounds {
    final cs = corners;
    var l = cs.first.dx, r = l, t = cs.first.dy, b = t;
    for (final p in cs) {
      l = math.min(l, p.dx);
      r = math.max(r, p.dx);
      t = math.min(t, p.dy);
      b = math.max(b, p.dy);
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  bool contains(double x, double y) {
    final dx = x - cx, dy = y - cy;
    final c = math.cos(angle), s = math.sin(angle);
    final u = dx * c + dy * s, v = -dx * s + dy * c;
    return u.abs() <= w / 2 && v.abs() <= h / 2;
  }

  /// Lo stesso rettangolo su un originale ricampionato ([sx], [sy] = nuovo
  /// / vecchio): serve all'esportazione ad alta risoluzione.
  InkFill scaled(double sx, double sy) => InkFill(
    cx: cx * sx,
    cy: cy * sy,
    w: w * sx,
    h: h * sy,
    angle: angle,
    color: color,
  );

  /// Per passarlo ai calcoli in background (isolate) e per salvarlo.
  List<double> toList() => [cx, cy, w, h, angle, color.toDouble()];

  static InkFill fromList(List<double> l) => InkFill(
    cx: l[0],
    cy: l[1],
    w: l[2],
    h: l[3],
    angle: l[4],
    // i primi salvataggi avevano 1 = bianco, 0 = nero
    color: l[5] <= 1
        ? (l[5] > .5 ? whiteInk : black)
        : (l[5].round() | 0xFF000000),
  );
}

/// Colora nei pixel di [img] (l'originale) i rettangoli d'inchiostro.
/// [fills] come da [InkFill.toList], già alla scala di [img].
void applyInkFills(RasterImage img, List<List<double>> fills) {
  if (fills.isEmpty) return;
  final Uint8List px = img.rgba;
  for (final l in fills) {
    final f = InkFill.fromList(l);
    final b = f.bounds;
    final x0 = math.max(0, b.left.floor()),
        x1 = math.min(img.width, b.right.ceil());
    final y0 = math.max(0, b.top.floor()),
        y1 = math.min(img.height, b.bottom.ceil());
    final cr = (f.color >> 16) & 0xFF,
        cg = (f.color >> 8) & 0xFF,
        cb = f.color & 0xFF;
    for (var y = y0; y < y1; y++) {
      var i = (y * img.width + x0) * 4;
      for (var x = x0; x < x1; x++, i += 4) {
        // centro del pixel
        if (!f.contains(x + .5, y + .5)) continue;
        px[i] = cr;
        px[i + 1] = cg;
        px[i + 2] = cb;
        px[i + 3] = 255;
      }
    }
  }
}
