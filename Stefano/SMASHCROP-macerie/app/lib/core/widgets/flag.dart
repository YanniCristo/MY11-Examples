import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/strings.dart';

/// Bandiera della lingua disegnata dall'app: niente emoji, così appare
/// uguale su ogni telefono e browser (anche dove le emoji bandiera mancano).
class LangFlag extends StatelessWidget {
  const LangFlag(this.lang, {super.key, this.width = 24});

  final AppLang lang;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 2 / 3;
    return ClipRRect(
      borderRadius: BorderRadius.circular(width / 8),
      child: SizedBox(
        width: width,
        height: h,
        child: CustomPaint(painter: _FlagPainter(lang)),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.lang);
  final AppLang lang;

  static Paint _p(int c) => Paint()..color = Color(c);

  void _vertical(Canvas c, Size s, List<int> colors) {
    final w = s.width / colors.length;
    for (var i = 0; i < colors.length; i++) {
      c.drawRect(Rect.fromLTWH(i * w, 0, w + .5, s.height), _p(colors[i]));
    }
  }

  void _horizontal(Canvas c, Size s, List<int> colors, [List<double>? parts]) {
    final ps = parts ?? List.filled(colors.length, 1.0);
    final total = ps.reduce((a, b) => a + b);
    var y = 0.0;
    for (var i = 0; i < colors.length; i++) {
      final h = s.height * ps[i] / total;
      c.drawRect(Rect.fromLTWH(0, y, s.width, h + .5), _p(colors[i]));
      y += h;
    }
  }

  @override
  void paint(Canvas c, Size s) {
    switch (lang) {
      case AppLang.it:
        _vertical(c, s, [0xFF009246, 0xFFFFFFFF, 0xFFCE2B37]);
      case AppLang.fr:
        _vertical(c, s, [0xFF0055A4, 0xFFFFFFFF, 0xFFEF4135]);
      case AppLang.de:
        _horizontal(c, s, [0xFF000000, 0xFFDD0000, 0xFFFFCE00]);
      case AppLang.es:
        _horizontal(c, s, [0xFFAA151B, 0xFFF1BF00, 0xFFAA151B], [1, 2, 1]);
      case AppLang.en:
        _unionJack(c, s);
      case AppLang.pt:
        _brazil(c, s);
    }
  }

  void _unionJack(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _p(0xFF012169));
    final w = s.width, h = s.height;
    final diag = s.shortestSide * .2;
    final white = _p(0xFFFFFFFF)
      ..strokeWidth = diag
      ..style = PaintingStyle.stroke;
    final red = _p(0xFFC8102E)
      ..strokeWidth = diag * .45
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset.zero, Offset(w, h), white);
    c.drawLine(Offset(w, 0), Offset(0, h), white);
    c.drawLine(Offset.zero, Offset(w, h), red);
    c.drawLine(Offset(w, 0), Offset(0, h), red);
    final cross = s.shortestSide * .33;
    c.drawRect(
      Rect.fromCenter(center: s.center(Offset.zero), width: w, height: cross),
      _p(0xFFFFFFFF),
    );
    c.drawRect(
      Rect.fromCenter(center: s.center(Offset.zero), width: cross, height: h),
      _p(0xFFFFFFFF),
    );
    final rc = cross * .6;
    c.drawRect(
      Rect.fromCenter(center: s.center(Offset.zero), width: w, height: rc),
      _p(0xFFC8102E),
    );
    c.drawRect(
      Rect.fromCenter(center: s.center(Offset.zero), width: rc, height: h),
      _p(0xFFC8102E),
    );
  }

  void _brazil(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _p(0xFF009C3B));
    final w = s.width, h = s.height;
    final m = w * .085;
    c.drawPath(
      Path()
        ..moveTo(w / 2, m)
        ..lineTo(w - m, h / 2)
        ..lineTo(w / 2, h - m)
        ..lineTo(m, h / 2)
        ..close(),
      _p(0xFFFFDF00),
    );
    final r = h * .25;
    c.drawCircle(s.center(Offset.zero), r, _p(0xFF002776));
    c.drawArc(
      Rect.fromCircle(center: s.center(Offset(0, r * .5)), radius: r * 1.15),
      math.pi * 1.15,
      math.pi * .7,
      false,
      _p(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .22,
    );
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.lang != lang;
}

/// Freccetta verso il basso disegnata (non dipende dal font delle icone).
class ChevronDown extends StatelessWidget {
  const ChevronDown({super.key, this.size = 14, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _ChevronPainter(color)),
  );
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    c.drawPath(
      Path()
        ..moveTo(s.width * .18, s.height * .36)
        ..lineTo(s.width * .5, s.height * .68)
        ..lineTo(s.width * .82, s.height * .36),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}
