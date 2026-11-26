import 'dart:math' as math;
import 'dart:ui' as ui;

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

  /// Raggio in cui si prende una maniglia (sullo schermo).
  static const double gripRadius = 34;

  /// Distanza delle maniglie dall'angolo, in fuori lungo la diagonale: così
  /// non coprono la parte che verrà colorata.
  static const double gripOut = 22;

  /// Centro della maniglia dell'angolo [k] del rettangolo [r], sullo schermo.
  static Offset gripAt(EditorController c, OctoRect r, int k) {
    final o = c.contentToScreen(r.center);
    final p = c.contentToScreen(r.corner(k));
    final d = p - o;
    final len = d.distance;
    return len < 1e-6 ? p : p + d / len * gripOut;
  }

  int? _rect;
  Offset? _down;
  // differenza fra angolo vero e punto del dito, per ridimensionare
  Offset _grab = Offset.zero;
  OctoGrip? _grip;
  int _corner = 0;
  Offset _last = Offset.zero;
  int _lastDeg = 999;

  bool get active => _grip != null;

  /// Prova a prendere un rettangolo nel punto [screen]. `true` se l'ha preso
  /// (allora il gesto non sposta né ingrandisce la pagina).
  void down(Offset screen) => _down = screen;

  bool start() {
    final screen = _down;
    if (screen == null ||
        !c.octoMode ||
        c.octoSplash != null ||
        c.octoAnimating) {
      return false;
    }
    // le maniglie (solo del rettangolo selezionato): vince la più vicina
    final s = c.octoSelected;
    if (s != null && s < c.octoRects.length) {
      final r = c.octoRects[s];
      var best = -1;
      var bestD = gripRadius;
      for (var k = 0; k < 4; k++) {
        final d = (gripAt(c, r, k) - screen).distance;
        if (d <= bestD) {
          bestD = d;
          best = k;
        }
      }
      if (best >= 0) return _take(s, gripOf(best), best, screen);
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
    _grab = corner >= 0 ? c.octoRects[i].corner(corner) - _last : Offset.zero;
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
        r.resizeFrom(_corner, p + _grab);
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
/// I 18 fotogrammi di OctoSmash (per ora solo la linea Bianca), con i piedi
/// già allineati a y = 335 sulla tela 730×470.
abstract final class OctoFrames {
  static const int count = 18;
  static const double feetY = 335, bodyH = 210;

  /// Dove arriva lo spruzzo nel fotogramma 6 (pixel della tela 730×470).
  static const Offset splashAt = Offset(490, 215);

  /// Fotogrammi per linea: 'bianco' (inchiostro nero e colori) e 'nero'
  /// (inchiostro bianco).
  static final Map<String, List<ui.Image>> lines = {};
  static final Set<String> _loading = {};

  static void load() {
    for (final line in const ['bianco', 'nero']) {
      if (lines.containsKey(line) || !_loading.add(line)) continue;
      () async {
        // tutti i fotogrammi insieme, non uno dopo l'altro
        final list = await Future.wait([
          for (var i = 1; i <= count; i++)
            () async {
              final data = await rootBundle.load(
                'assets/octo/$line/octo_${i.toString().padLeft(2, '0')}.webp',
              );
              final codec = await ui.instantiateImageCodec(
                data.buffer.asUint8List(),
              );
              final img = (await codec.getNextFrame()).image;
              codec.dispose();
              return img;
            }(),
        ]);
        lines[line] = list;
      }().catchError((Object e) {
        debugPrint('OctoFrames $line: $e');
        _loading.remove(line);
      });
    }
  }
}

class OctoPainter extends CustomPainter {
  OctoPainter(this.c) : super(repaint: c) {
    OctoFrames.load();
  }
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
    if (c.octoAnimating) _paintRobot(canvas, size);
    final pick = c.octoPickAt;
    if (c.octoPicking && pick != null) _paintLoupe(canvas, size, pick);
    if (c.octoPicking && pick == null) _hint(canvas, size);
    for (var i = 0; i < c.octoRects.length; i++) {
      final r = c.octoRects[i];
      final pts = _screen(r);
      final path = Path()..addPolygon(pts, true);
      // velato: si vede bene cosa c'è sotto finché non si preme "Fatto"
      canvas.drawPath(path, Paint()..color = _veil(r.color));
      final sel = i == c.octoSelected;
      // contorno solo per vederlo: sta fuori dal rettangolo, non colora
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sel ? 2.4 : 1.4
          ..color = sel
              ? _cyan
              : (Color(r.color).computeLuminance() > .4
                    ? const Color(0xFF5A606A)
                    : const Color(0xFFB8BEC8)),
      );
      if (sel) {
        if (c.octoRotating) _guides(canvas, size, c.contentToScreen(r.center));
        for (var k = 0; k < 4; k++) {
          final g = OctoGestures.gripAt(c, r, k);
          canvas.drawLine(
            pts[k],
            g,
            Paint()
              ..color = _cyan
              ..strokeWidth = 2,
          );
          _grip(canvas, g, gripOf(k));
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
    canvas.drawCircle(at, 16, Paint()..color = _cyan);
    canvas.drawCircle(
      at,
      16,
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
        ((DateTime.now().millisecondsSinceEpoch - c.octoSplashStart) /
                c.octoSplashDuration)
            .clamp(0.0, 1.0);
    for (final r in rs) {
      final pts = _screen(r);
      final path = Path()..addPolygon(pts, true);
      // in attesa dello spruzzo resta velato com'era
      canvas.drawPath(path, Paint()..color = _veil(r.color));
      final b = path.getBounds();
      final paint = Paint()..color = Color(r.color);
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

  void _hint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Appoggia il dito sul colore e lascia',
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width - 40);
    final box = Rect.fromCenter(
      center: Offset(size.width / 2, 30),
      width: tp.width + 28,
      height: tp.height + 14,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(20)),
      Paint()..color = _cyan,
    );
    tp.paint(canvas, box.center - Offset(tp.width / 2, tp.height / 2));
  }

  static Color _veil(int color) => Color(color).withValues(alpha: .5);

  /// Lente sopra il dito: ingrandisce la pagina sotto il mirino, così il
  /// dito non copre il colore che si sta prendendo.
  void _paintLoupe(Canvas canvas, Size size, Offset at) {
    final img = c.pageImage;
    final o = c.contentToOriginal(c.screenToContent(at));
    const r = 54.0, zoom = 5.0;
    var centre = at - const Offset(0, 96);
    if (centre.dy < r + 4) centre = at + const Offset(0, 96);
    final circle = Rect.fromCircle(center: centre, radius: r);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawRect(circle, Paint()..color = const Color(0xFF15171D));
    if (img != null && o != null) {
      // pixel dell'originale mostrati in ogni lato della lente
      final span = 2 * r / (c.transform.scale * zoom);
      canvas.drawImageRect(
        img,
        Rect.fromCenter(center: o, width: span, height: span),
        circle,
        Paint()..filterQuality = FilterQuality.none,
      );
    }
    canvas.restore();
    // anello del colore che si sta per prendere
    final live = c.livePickColor;
    canvas.drawCircle(
      centre,
      r + 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = live == null ? Colors.white : Color(live),
    );
    canvas.drawCircle(
      centre,
      r - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
    canvas.drawCircle(
      centre,
      r + 8.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black54,
    );
    // mirino
    final m = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black;
    canvas.drawRect(Rect.fromCenter(center: centre, width: 10, height: 10), m);
    canvas.drawRect(
      Rect.fromCenter(center: centre, width: 12, height: 12),
      m..color = Colors.white,
    );
  }

  /// OctoSmash attraversa la pagina come SMASH: entra, spruzza, esce.
  void _paintRobot(Canvas canvas, Size size) {
    // inchiostro bianco → OctoSmash Nero; nero e colori → OctoSmash Bianco
    final imgs = OctoFrames.lines[c.octoAnimWhiteInk ? 'nero' : 'bianco'];
    if (imgs == null) return;
    final ms = DateTime.now().millisecondsSinceEpoch - c.octoAnimStart;
    final i = (ms ~/ EditorController.octoFrameMs).clamp(0, imgs.length - 1);
    final s = size.width * .32 / OctoFrames.bodyH;
    final w = 730 * s, h = 470 * s;
    var left = (size.width - w) / 2;
    var top = size.height * .62 - OctoFrames.feetY * s;
    // si sposta perché lo spruzzo arrivi sul rettangolo, restando però
    // dentro lo schermo (se il rettangolo è sul bordo, ci arriva vicino)
    final target = c.octoAnimTarget;
    if (target != null) {
      final p = c.contentToScreen(target);
      left = p.dx - OctoFrames.splashAt.dx * s;
      top = p.dy - OctoFrames.splashAt.dy * s;
      left = left.clamp(-200 * s, size.width - 520 * s);
      top = top.clamp(-80 * s, size.height - 345 * s);
    }
    canvas.drawImageRect(
      imgs[i],
      const Rect.fromLTWH(0, 0, 730, 470),
      Rect.fromLTWH(left, top, w, h),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(OctoPainter old) => true;
}
