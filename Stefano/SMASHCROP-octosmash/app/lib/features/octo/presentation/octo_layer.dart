import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../editor/application/editor_controller.dart';
import '../domain/octo_rect.dart';

/// Cosa fa ogni angolo del rettangolo: 0 e 2 ridimensionano, 3 sposta,
/// 1 ruota.
enum OctoGrip { resize, move, rotate }

OctoGrip gripOf(int corner) => switch (corner) {
  1 => OctoGrip.rotate,
  3 => OctoGrip.move,
  _ => OctoGrip.resize,
};

/// Gestisce col dito i rettangoli di OctoSmash dentro il viewport.
/// (Il disegno è in [OctoPainter].)
class OctoGestures {
  OctoGestures(this.c);
  final EditorController c;

  static const double gripRadius = 26;

  int? _rect;
  OctoGrip? _grip;
  int _corner = 0;
  Offset _last = Offset.zero;
  int _lastDeg = 999;

  bool get active => _grip != null;

  /// Prova a prendere un rettangolo nel punto [screen]. `true` se l'ha preso
  /// (allora il gesto non sposta né ingrandisce la pagina).
  bool start(Offset screen) {
    if (!c.octoMode || c.octoSplash != null) return false;
    // prima gli angoli del rettangolo selezionato, poi quelli degli altri
    final order = [
      if (c.octoSelected != null) c.octoSelected!,
      for (var i = c.octoRects.length - 1; i >= 0; i--)
        if (i != c.octoSelected) i,
    ];
    for (final i in order) {
      final r = c.octoRects[i];
      for (var k = 0; k < 4; k++) {
        if ((c.contentToScreen(r.corner(k)) - screen).distance <= gripRadius) {
          return _take(i, gripOf(k), k, screen);
        }
      }
    }
    final p = c.screenToContent(screen);
    for (var i = c.octoRects.length - 1; i >= 0; i--) {
      if (c.octoRects[i].contains(p)) {
        return _take(i, OctoGrip.move, -1, screen);
      }
    }
    return false;
  }

  bool _take(int i, OctoGrip g, int corner, Offset screen) {
    _rect = i;
    _grip = g;
    _corner = corner;
    _last = c.screenToContent(screen);
    _lastDeg = 999;
    if (c.octoSelected != i) c.selectOcto(i);
    return true;
  }

  void update(Offset screen) {
    final i = _rect, g = _grip;
    if (i == null || g == null || i >= c.octoRects.length) return;
    final r = c.octoRects[i];
    final p = c.screenToContent(screen);
    switch (g) {
      case OctoGrip.move:
        r.move(p - _last);
      case OctoGrip.resize:
        r.resizeFrom(_corner, p);
      case OctoGrip.rotate:
        r.rotateTo(p);
        // una vibrazione leggera quando è esattamente dritto (niente calamita)
        final d = r.degrees;
        if (d % 90 == 0 && d != _lastDeg) HapticFeedback.selectionClick();
        _lastDeg = d;
    }
    _last = p;
    c.octoChanged(rotating: g == OctoGrip.rotate);
  }

  void end() {
    if (_grip == null) return;
    _grip = null;
    _rect = null;
    c.octoChanged();
  }

  /// Tocco singolo: seleziona il rettangolo toccato, o nessuno.
  void tap(Offset screen) {
    if (!c.octoMode) return;
    final p = c.screenToContent(screen);
    for (var i = c.octoRects.length - 1; i >= 0; i--) {
      if (c.octoRects[i].contains(p)) {
        c.selectOcto(i);
        return;
      }
    }
    c.selectOcto(null);
  }
}

/// Disegna i rettangoli di OctoSmash (pieni del loro colore: il contorno e le
/// maniglie non coprono niente), le guide tratteggiate mentre si ruota e lo
/// spruzzo d'inchiostro dopo "Fatto".
class OctoPainter extends CustomPainter {
  OctoPainter(this.c) : super(repaint: c);
  final EditorController c;

  static const _cyan = Color(0xFF22E4F2);

  List<Offset> _screen(OctoRect r) => [
    for (var k = 0; k < 4; k++) c.contentToScreen(r.corner(k)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final splash = c.octoSplash;
    if (splash != null) _paintSplash(canvas, splash);
    for (var i = 0; i < c.octoRects.length; i++) {
      final r = c.octoRects[i];
      final pts = _screen(r);
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(
        path,
        Paint()..color = r.white ? Colors.white : Colors.black,
      );
      final sel = i == c.octoSelected;
      // contorno solo per vederlo: sta fuori dal rettangolo, non colora
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sel ? 2.4 : 1.4
          ..color = sel
              ? _cyan
              : (r.white ? const Color(0xFF9AA0AA) : const Color(0xFF5A606A)),
      );
      if (sel) {
        if (c.octoRotating) _guides(canvas, size, c.contentToScreen(r.center));
        for (var k = 0; k < 4; k++) {
          _grip(canvas, pts[k], gripOf(k));
        }
      }
    }
  }

  void _guides(Canvas canvas, Size size, Offset o) {
    final p = Paint()
      ..color = _cyan.withValues(alpha: .8)
      ..strokeWidth = 1.2;
    const dash = 7.0, gap = 5.0;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, o.dy), Offset(x + dash, o.dy), p);
    }
    for (double y = 0; y < size.height; y += dash + gap) {
      canvas.drawLine(Offset(o.dx, y), Offset(o.dx, y + dash), p);
    }
  }

  void _grip(Canvas canvas, Offset at, OctoGrip g) {
    canvas.drawCircle(at, 15, Paint()..color = _cyan);
    canvas.drawCircle(
      at,
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    final icon = switch (g) {
      OctoGrip.resize => Icons.open_in_full,
      OctoGrip.move => Icons.open_with,
      OctoGrip.rotate => Icons.rotate_right,
    };
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: 17,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  /// Gocce d'inchiostro che si allargano dentro ogni rettangolo e lo
  /// riempiono in poco più di mezzo secondo.
  void _paintSplash(Canvas canvas, List<OctoRect> rs) {
    final t =
        ((DateTime.now().millisecondsSinceEpoch - c.octoSplashStart) / 550)
            .clamp(0.0, 1.0);
    for (final r in rs) {
      final pts = _screen(r);
      final path = Path()..addPolygon(pts, true);
      final b = path.getBounds();
      final paint = Paint()..color = r.white ? Colors.white : Colors.black;
      canvas.save();
      canvas.clipPath(path);
      final rnd = math.Random(r.hashCode);
      final big = math.max(b.width, b.height);
      for (var k = 0; k < 9; k++) {
        final o = Offset(
          b.left + rnd.nextDouble() * b.width,
          b.top + rnd.nextDouble() * b.height,
        );
        final delay = rnd.nextDouble() * .35;
        final e = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
        canvas.drawCircle(o, big * Curves.easeOut.transform(e), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(OctoPainter old) => true;
}
