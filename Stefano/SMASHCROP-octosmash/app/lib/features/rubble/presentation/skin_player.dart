import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../animation/domain/smash_config.dart';
import '../application/skin_assets.dart';
import '../domain/skins.dart';
import 'skin_effects.dart';

/// Mostra un personaggio della Collezione: fa una volta tutta la sua
/// animazione (con gli elementi della fascia che esplodono dietro) e poi
/// resta a riposo con il pollice alzato, dondolando tra le immagini 15 e 16.
class SkinPlayer extends StatefulWidget {
  const SkinPlayer({
    super.key,
    required this.skin,
    this.playId = 0,
    this.locked = false,
    this.placeholder,
    this.restFrames = const (14, 15),
    this.onImpact,
  });

  final SkinDef skin;

  /// Cambiandolo l'animazione riparte.
  final int playId;

  /// Bloccata: sagoma scura, ferma.
  final bool locked;

  /// Immagine da mostrare mentre l'animazione carica, al posto della posa.
  final String? placeholder;

  /// I due fotogrammi che si alternano a riposo, dopo l'animazione.
  final (int, int) restFrames;

  /// Chiamata una volta a ogni animazione, nel momento del colpo (0,5 s
  /// dopo l'inizio, quando escono gli effetti): serve per il suono.
  final VoidCallback? onImpact;

  @override
  State<SkinPlayer> createState() => _SkinPlayerState();
}

class _SkinPlayerState extends State<SkinPlayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  SkinImages? _imgs;
  double _ms = 0;
  double _startedAt = 0;

  static const _fd = 100.0; // 10 fotogrammi al secondo

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SkinPlayer old) {
    super.didUpdateWidget(old);
    if (old.skin.id != widget.skin.id) {
      _imgs = null;
      _load();
    } else if (old.playId != widget.playId) {
      _startedAt = _ms;
      _impactDone = false;
    }
  }

  Future<void> _load() async {
    final s = widget.skin;
    try {
      final imgs = await SkinImages.load(s);
      if (!mounted || widget.skin.id != s.id) return;
      setState(() {
        _imgs = imgs;
        _startedAt = _ms;
        _impactDone = false;
      });
      if (!_ticker.isActive) _ticker.start();
    } catch (_) {}
  }

  bool _impactDone = true;

  void _onTick(Duration d) {
    setState(() => _ms = d.inMicroseconds / 1000);
    if (!_impactDone && !widget.locked && _ms - _startedAt >= 500) {
      _impactDone = true;
      widget.onImpact?.call();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  int _frame() {
    if (widget.locked) return 14;
    final t = _ms - _startedAt;
    var acc = 0.0;
    for (var i = 0; i < SmashSprite.frameCount; i++) {
      acc += SmashSprite.frameUnits[i] * _fd;
      // le ultime due immagini sono l'uscita: si torna a riposo prima
      if (i == 15) break;
      if (t < acc) return i;
    }
    // riposo: 15 e 16 alternate lentamente
    final (a, b) = widget.restFrames;
    return ((t / 600).floor() % 2 == 0) ? a : b;
  }

  @override
  Widget build(BuildContext context) {
    final imgs = _imgs;
    if (imgs == null) {
      // mentre l'animazione arriva si vede subito la posa da eroe
      // (un'immagine sola), o la sua sagoma se è ancora bloccato
      final pose = Image.asset(
        widget.placeholder ?? widget.skin.pose,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
      return Padding(
        padding: const EdgeInsets.all(12),
        child: widget.locked
            ? ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF15161C),
                  BlendMode.srcIn,
                ),
                child: pose,
              )
            : pose,
      );
    }
    return CustomPaint(
      painter: _PlayerPainter(
        imgs,
        _frame(),
        widget.locked ? null : (_ms - _startedAt) / 1000,
        widget.locked,
      ),
      size: Size.infinite,
    );
  }
}

class _PlayerPainter extends CustomPainter {
  _PlayerPainter(this.imgs, this.frame, this.sec, this.locked);
  final SkinImages imgs;
  final int frame;
  final double? sec;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    // il robot occupa la tela 730×470: la si centra sul robot (x 150–600)
    const src = Rect.fromLTWH(120, 0, 520, 420);
    final k = (size.width / src.width).clamp(0.0, size.height / src.height);
    final w = src.width * k, h = src.height * k;
    final dst = Rect.fromLTWH(
      (size.width - w) / 2,
      (size.height - h) / 2,
      w,
      h,
    );
    // elementi della fascia che esplodono dal punto del colpo
    final t = sec == null ? null : sec! - 0.5;
    if (t != null && t > 0 && t < 1.4) {
      final c = dst.topLeft + (imgs.skin.impactAnchor - src.topLeft) * k;
      for (var i = 0; i < 10; i++) {
        final ang = -2.6 + i * .52;
        final v = Offset(_cos(ang), _sin(ang)) * (140 + (i % 3) * 50) * k * 1.6;
        final p = c + v * t + Offset(0, 500 * k * t * t);
        final a = (1 - t / 1.4).clamp(0.0, 1.0);
        final img = imgs.elements[i % 6];
        final s = 30 * k * 1.6;
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCenter(center: p, width: s, height: s),
          Paint()..color = Color.fromRGBO(0, 0, 0, a),
        );
      }
    }
    // il tocco della skin, come nell'editor
    if (t != null && t > SkinEffects.start && t < SkinEffects.end) {
      final c = dst.topLeft + (imgs.skin.impactAnchor - src.topLeft) * k;
      SkinEffects.paint(
        canvas,
        skinId: imgs.skin.id,
        strip: Rect.fromCenter(center: c, width: 200 * k, height: 60 * k),
        impact: c,
        sec: t,
        power: .75,
        seed: 7,
      );
    }
    final img = imgs.frames[frame];
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (locked) {
      paint.colorFilter = const ColorFilter.mode(
        Color(0xFF15161C),
        BlendMode.srcIn,
      );
    }
    canvas.drawImageRect(img, src, dst, paint);
  }

  static double _cos(double a) => ui.Offset.fromDirection(a).dx;
  static double _sin(double a) => ui.Offset.fromDirection(a).dy;

  @override
  bool shouldRepaint(_PlayerPainter old) => true;
}
