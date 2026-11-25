import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

enum AppButtonStyle {
  /// Rosso pieno con sfumatura: azioni principali.
  primary,

  /// Antracite: azioni normali.
  secondary,

  /// Rosso pieno senza sfumatura: modalità attiva (Orizzontale/Verticale).
  selected,
}

/// Pulsante dell'app: stessa forma ovunque, una sola responsabilità.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.style = AppButtonStyle.secondary,
    this.height = 44,
    this.fontSize = 15,
    this.hideIconBelow = 0,
    this.semanticLabel,
    this.dimmed = false,
  });

  /// Aspetto attenuato pur restando premibile (es. funzione in arrivo).
  final bool dimmed;

  final String label;
  final Widget? icon;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final double height;
  final double fontSize;

  /// Sotto questa larghezza l'icona sparisce e resta solo il testo.
  final double hideIconBelow;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final decoration = switch (style) {
      AppButtonStyle.primary => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.redLight, AppColors.redDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55E5172F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      AppButtonStyle.selected => BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.redLight),
      ),
      AppButtonStyle.secondary => BoxDecoration(
        color: AppColors.button,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: enabled && !dimmed ? 1 : .4,
          child: Container(
            height: height,
            decoration: decoration,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onPressed,
                child: LayoutBuilder(
                  builder: (context, c) {
                    // se con l'icona il testo dovrebbe rimpicciolirsi troppo
                    // (lingue con parole lunghe), si toglie l'icona
                    var showIcon = icon != null && c.maxWidth >= hideIconBelow;
                    if (showIcon && label.isNotEmpty && c.maxWidth.isFinite) {
                      final tp = TextPainter(
                        text: TextSpan(
                          text: label,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                        maxLines: 1,
                      )..layout();
                      final room = c.maxWidth - 16 - (fontSize + 5) - 7;
                      if (tp.width * .82 > room) showIcon = false;
                      tp.dispose();
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showIcon && label.isEmpty) icon!,
                          if (showIcon && label.isNotEmpty) ...[
                            IconTheme(
                              data: IconThemeData(
                                color: AppColors.text,
                                size: fontSize + 5,
                              ),
                              child: icon!,
                            ),
                            const SizedBox(width: 7),
                          ],
                          // testi più lunghi in alcune lingue: si
                          // rimpiccioliscono quanto serve, mai tagliati
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Freccia doppia disegnata (↕ o ↔), uguale su iOS e Android.
class DoubleArrow extends StatelessWidget {
  const DoubleArrow({
    super.key,
    required this.vertical,
    this.size = 18,
    this.color,
  });

  final bool vertical;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? AppColors.text;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ArrowPainter(vertical, c)),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.vertical, this.color);
  final bool vertical;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = s.width * .12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.save();
    if (!vertical) {
      canvas.translate(s.width / 2, s.height / 2);
      canvas.rotate(1.5707963);
      canvas.translate(-s.width / 2, -s.height / 2);
    }
    final w = s.width, h = s.height, a = w * .26;
    canvas.drawLine(Offset(w / 2, h * .1), Offset(w / 2, h * .9), p);
    final path = Path()
      ..moveTo(w / 2 - a, h * .1 + a)
      ..lineTo(w / 2, h * .1)
      ..lineTo(w / 2 + a, h * .1 + a)
      ..moveTo(w / 2 - a, h * .9 - a)
      ..lineTo(w / 2, h * .9)
      ..lineTo(w / 2 + a, h * .9 - a);
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.vertical != vertical || old.color != color;
}
