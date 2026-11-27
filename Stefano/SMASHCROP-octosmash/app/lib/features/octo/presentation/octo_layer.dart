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
/// Un OctoSmash pronto da disegnare: il suo atlante (18 fotogrammi 730×470 in
/// una griglia 5×4, come SMASH) e, se ce l'ha, l'atlante dell'inchiostro da
/// ricolorare, ritagliato sulla zona dove c'è davvero.
class OctoLine {
  OctoLine(this.body, this.ink, this.inkBox);
  final ui.Image body;
  final ui.Image? ink;
  final Rect? inkBox;

  void dispose() {
    body.dispose();
    ink?.dispose();
  }

  /// Disegna il fotogramma [i] (0–17) dentro [dst] (la tela 730×470 intera),
  /// con l'inchiostro del colore [inkColor].
  void draw(Canvas canvas, int i, Rect dst, Color inkColor) {
    const w = 730.0, h = 470.0;
    final col = i % 5, row = i ~/ 5;
    final p = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(body, Rect.fromLTWH(col * w, row * h, w, h), dst, p);
    final k = ink, b = inkBox;
    if (k == null || b == null) return;
    final sx = dst.width / w, sy = dst.height / h;
    canvas.drawImageRect(
      k,
      Rect.fromLTWH(col * b.width, row * b.height, b.width, b.height),
      Rect.fromLTWH(
        dst.left + b.left * sx,
        dst.top + b.top * sy,
        b.width * sx,
        b.height * sy,
      ),
      p..colorFilter = ColorFilter.mode(inkColor, BlendMode.modulate),
    );
  }
}

/// Carica gli OctoSmash solo quando servono e ne tiene in memoria pochi: su
/// iPhone tenerli tutti (oltre 300 MB) faceva tacere l'audio e rallentare.
abstract final class OctoFrames {
  static const int count = 18;
  static const double feetY = 335, bodyH = 210;

  /// Dove arriva lo spruzzo nel fotogramma 6 (pixel della tela 730×470).
  static const Offset splashAt = Offset(490, 215);

  /// Zona dell'inchiostro in ogni fotogramma (chi non ce l'ha non si ricolora).
  static const Map<String, Rect> _inkBox = {
    'pipetta': Rect.fromLTWH(0, 97, 665, 240),
    'multicolor': Rect.fromLTWH(400, 90, 198, 246),
    'fusione': Rect.fromLTWH(0, 107, 666, 231),
    'stampa': Rect.fromLTWH(0, 127, 618, 210),
    'abisso': Rect.fromLTWH(210, 187, 376, 150),
    'diluvio': Rect.fromLTWH(0, 126, 614, 211),
    'imperatore': Rect.fromLTWH(0, 148, 628, 194),
  };

  static const int _keep = 2;
  static final Map<String, OctoLine> _lines = {};
  static final List<String> _recent = [];
  static final Map<String, Future<void>> _loading = {};

  /// Il personaggio, se è già pronto (e lo segna come appena usato).
  static OctoLine? line(String id) {
    final l = _lines[id];
    if (l != null) _touch(id);
    return l;
  }

  static void _touch(String id) {
    _recent
      ..remove(id)
      ..add(id);
  }

  /// Prepara un personaggio (in sottofondo). Chiamarlo appena si sa chi
  /// spruzzerà, così l'animazione è pronta prima di "Fatto".
  static Future<void> ensure(String id) {
    if (_lines.containsKey(id)) {
      _touch(id);
      return Future.value();
    }
    return _loading[id] ??= _load(id).whenComplete(() => _loading.remove(id));
  }

  static Future<ui.Image> _image(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final img = (await codec.getNextFrame()).image;
    codec.dispose();
    return img;
  }

  static Future<void> _load(String id) async {
    try {
      final box = _inkBox[id];
      final body = await _image('assets/octo/$id/atlas.webp');
      final ink = box == null
          ? null
          : await _image('assets/octo/$id/ink_atlas.webp');
      _lines[id] = OctoLine(body, ink, box);
      _touch(id);
      // ne restano in memoria solo gli ultimi usati
      while (_recent.length > _keep) {
        _lines.remove(_recent.removeAt(0))?.dispose();
      }
      _loadEffects(id);
    } catch (e) {
      debugPrint('OctoFrames $id: $e');
    }
  }

  /// Effetti speciali delle evoluzioni: 6 elementi che volano allo spruzzo.
  static final Map<String, List<ui.Image>> effects = {};
  static final Set<String> _fxLoading = {};

  static void _loadEffects(String evo) {
    const evos = {'fusione', 'stampa', 'abisso', 'diluvio', 'imperatore'};
    if (!evos.contains(evo) ||
        effects.containsKey(evo) ||
        !_fxLoading.add(evo)) {
      return;
    }
    Future.wait([
      for (var i = 1; i <= 6; i++) _image('assets/octo/effetti/${evo}_$i.webp'),
    ]).then(
      (l) => effects[evo] = l,
      onError: (Object _) {
        _fxLoading.remove(evo);
        return const <ui.Image>[];
      },
    );
  }
}

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
    if (c.octoAnimating) {
      _paintRobot(canvas, size);
      _paintEffects(canvas);
    }
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

  /// Gli elementi dell'evoluzione (scintille, bollicine, monetine...)
  /// schizzano fuori dal rettangolo quando arriva lo spruzzo, ricadono e
  /// svaniscono in meno di un secondo.
  void _paintEffects(Canvas canvas) {
    final evo = c.octoEvolution;
    final target = c.octoAnimTarget;
    if (evo == null || target == null) return;
    final imgs = OctoFrames.effects[evo];
    if (imgs == null) return;
    final t =
        (DateTime.now().millisecondsSinceEpoch - c.octoSplashStart) / 1000;
    if (t < 0 || t > 1) return;
    final o = c.contentToScreen(target);
    final rnd = math.Random(c.octoAnimStart);
    for (var k = 0; k < 12; k++) {
      final img = imgs[k % imgs.length];
      final ang = -math.pi / 2 + (rnd.nextDouble() - .5) * math.pi * 1.6;
      final speed = 160 + rnd.nextDouble() * 220;
      final p =
          o +
          Offset(math.cos(ang), math.sin(ang)) * speed * t +
          Offset(0, 420 * t * t); // ricade
      final size = 26 + rnd.nextDouble() * 22;
      final spin = (rnd.nextDouble() - .5) * 6 * t;
      final alpha = (1 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(spin);
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: Offset.zero, width: size, height: size),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(0, 0, 0, alpha),
      );
      canvas.restore();
    }
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
    // chi spruzza: l'evoluzione scelta, altrimenti il personaggio del tasto
    final line = c.octoLine;
    final l = OctoFrames.line(line);
    if (l == null) {
      OctoFrames.ensure(line);
      return;
    }
    final ms = DateTime.now().millisecondsSinceEpoch - c.octoAnimStart;
    final i = (ms ~/ EditorController.octoFrameMs).clamp(
      0,
      OctoFrames.count - 1,
    );
    final s = size.width * .32 / OctoFrames.bodyH;
    final w = 730 * s, h = 470 * s;
    // posizione di sempre: entra dal bordo sinistro, esce dal destro
    final left0 = (size.width - w) / 2;
    var left = left0;
    var top = size.height * .62 - OctoFrames.feetY * s;
    final target = c.octoAnimTarget;
    if (target != null) {
      // per lo spruzzo si mette in modo che il getto arrivi sul rettangolo
      // (restando dentro lo schermo: sul bordo ci arriva vicino)
      final p = c.contentToScreen(target);
      final aimLeft = (p.dx - OctoFrames.splashAt.dx * s).clamp(
        -200 * s,
        size.width - 520 * s,
      );
      top = (p.dy - OctoFrames.splashAt.dy * s).clamp(
        -80 * s,
        size.height - 345 * s,
      );
      // entrando scivola dal bordo verso quel punto, uscendo torna verso
      // l'altro bordo: così entra ed esce sempre dai lati dell'immagine
      final f = ms / EditorController.octoFrameMs;
      final enter = Curves.easeInOut.transform(((f - .5) / 2.5).clamp(0, 1));
      final leave = Curves.easeInOut.transform(((f - 15) / 2.5).clamp(0, 1));
      final k = enter * (1 - leave);
      left = left0 + (aimLeft - left0) * k;
    }
    l.draw(canvas, i, Rect.fromLTWH(left, top, w, h), Color(c.octoAnimColor));
  }

  @override
  bool shouldRepaint(OctoPainter old) => true;
}
