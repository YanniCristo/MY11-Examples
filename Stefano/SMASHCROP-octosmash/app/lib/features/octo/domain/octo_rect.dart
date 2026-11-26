import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'ink_fill.dart';

/// Un rettangolo di OctoSmash ancora in lavorazione (prima di "Fatto"), in
/// pixel del documento **attuale**. Si sposta, si ridimensiona e si ruota.
class OctoRect {
  OctoRect({
    required this.center,
    required this.w,
    required this.h,
    this.angle = 0,
    required this.color,
  });

  Offset center;
  double w, h;

  /// Radianti, senso orario sullo schermo.
  double angle;

  /// Colore dell'inchiostro (ARGB opaco): bianco, nero o un colore preso
  /// con la pipetta o dalla tavolozza.
  int color;

  bool get white => color == InkFill.whiteInk;

  static const double minSide = 8;

  Offset _rot(Offset v, double a) {
    final c = math.cos(a), s = math.sin(a);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  /// Angolo [i] (0 in alto a sinistra, 1 in alto a destra, 2 in basso a
  /// destra, 3 in basso a sinistra), già ruotato.
  Offset corner(int i) {
    final hw = w / 2, hh = h / 2;
    final local = switch (i) {
      0 => Offset(-hw, -hh),
      1 => Offset(hw, -hh),
      2 => Offset(hw, hh),
      _ => Offset(-hw, hh),
    };
    return center + _rot(local, angle);
  }

  bool contains(Offset p) {
    final l = _rot(p - center, -angle);
    return l.dx.abs() <= w / 2 && l.dy.abs() <= h / 2;
  }

  void move(Offset delta) => center += delta;

  /// Tira l'angolo [i] fino a [p]: l'angolo opposto resta fermo.
  void resizeFrom(int i, Offset p) {
    final fixed = corner((i + 2) % 4);
    final d = _rot(p - fixed, -angle);
    w = math.max(minSide, d.dx.abs());
    h = math.max(minSide, d.dy.abs());
    // il centro a metà tra l'angolo fermo e quello tirato (con le misure
    // minime rispettate)
    final sx = d.dx >= 0 ? 1 : -1, sy = d.dy >= 0 ? 1 : -1;
    center = fixed + _rot(Offset(sx * w / 2, sy * h / 2), angle);
  }

  /// Ruota tirando l'angolo in alto a destra fino a [p].
  void rotateTo(Offset p) {
    final v = p - center;
    final base = math.atan2(-h / 2, w / 2);
    angle = _whole(math.atan2(v.dy, v.dx) - base);
  }

  /// Sempre a gradi interi: quello che dice il numero è l'angolo vero
  /// (90° è a piombo, non 89,6°).
  static double _whole(double a) {
    final d = (_norm(a) * 180 / math.pi).round();
    return _norm(d * math.pi / 180);
  }

  static double _norm(double a) {
    final t = 2 * math.pi;
    a %= t;
    if (a > math.pi) a -= t;
    if (a <= -math.pi) a += t;
    return a;
  }

  void rotateBy(double deg) => angle = _whole(angle + deg * math.pi / 180);

  /// Gradi interi per il tasto dell'angolo (-179…180).
  int get degrees => (angle * 180 / math.pi).round();

  /// Superficie in pixel del documento.
  double get area => w * h;

  InkFill toFill(Offset originalCenter) => InkFill(
    cx: originalCenter.dx,
    cy: originalCenter.dy,
    w: w,
    h: h,
    angle: angle,
    color: color,
  );
}
