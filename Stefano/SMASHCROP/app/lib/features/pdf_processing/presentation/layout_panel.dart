import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/page_layout.dart';

/// Pannello temporaneo con le quattro impaginazioni. Si apre al primo
/// taglio di una pagina o dal pulsante Layout PDF, e si chiude dopo la
/// conferma restituendo tutto lo spazio al documento.
class LayoutPanel extends StatelessWidget {
  const LayoutPanel({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onApply,
    required this.onClose,
    this.onApplyAll,
  });

  final PdfLayoutMode selected;
  final ValueChanged<PdfLayoutMode> onSelect;
  final VoidCallback onApply;
  final VoidCallback onClose;
  final VoidCallback? onApplyAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 36),
              const Expanded(
                child: Text(
                  S.layoutTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: S.cancel,
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              // quattro in fila se c'è spazio, altrimenti griglia 2×2
              final perRow = c.maxWidth >= 300 ? 4 : 2;
              final w = (c.maxWidth - 8 * (perRow - 1)) / perRow;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in PdfLayoutMode.values)
                    SizedBox(
                      width: w,
                      child: _Option(
                        mode: m,
                        selected: m == selected,
                        onTap: () => onSelect(m),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          AppButton(
            label: selected == PdfLayoutMode.custom
                ? S.placeContent
                : S.applyAndContinue,
            style: AppButtonStyle.primary,
            height: 48,
            fontSize: 16,
            onPressed: onApply,
          ),
          if (onApplyAll != null && selected != PdfLayoutMode.custom)
            TextButton(
              onPressed: onApplyAll,
              child: const Text(
                S.applyToAll,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              S.rasterNote,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final PdfLayoutMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: mode.label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 124,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.red : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MiniPage(mode),
                ),
              ),
              const SizedBox(height: 6),
              // una parola per riga, rimpicciolita se serve: mai spezzata a metà
              SizedBox(
                height: 32,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    mode.label.length > 10
                        ? mode.label.replaceFirst(' ', '\n')
                        : mode.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anteprima schematica: foglio bianco e contenuto ricongiunto in rosa.
class _MiniPage extends CustomPainter {
  _MiniPage(this.mode);
  final PdfLayoutMode mode;

  @override
  void paint(Canvas canvas, Size s) {
    const ratio = .72;
    final ph = s.height;
    final pw = ph * ratio;
    final page = Rect.fromLTWH((s.width - pw) / 2, 0, pw, ph);
    final contentH = ph * .46;
    final contentW = pw * .8;
    final pagePaint = Paint()..color = Colors.white;
    final content = Paint()..color = const Color(0xFFF5A3B5);
    final lines = Paint()..color = const Color(0xFFB7BCC6);
    Rect block;
    switch (mode) {
      case PdfLayoutMode.centered:
        canvas.drawRect(page, pagePaint);
        block = Rect.fromCenter(
          center: page.center,
          width: contentW,
          height: contentH,
        );
      case PdfLayoutMode.top:
        canvas.drawRect(page, pagePaint);
        block = Rect.fromLTWH(
          page.left + (pw - contentW) / 2,
          page.top + ph * .06,
          contentW,
          contentH,
        );
      case PdfLayoutMode.shrink:
        final small = Rect.fromCenter(
          center: page.center,
          width: pw,
          height: contentH + ph * .12,
        );
        canvas.drawRect(small, pagePaint);
        block = Rect.fromCenter(
          center: small.center,
          width: contentW,
          height: contentH,
        );
      case PdfLayoutMode.custom:
        canvas.drawRect(page, pagePaint);
        block = Rect.fromLTWH(
          page.left + (pw - contentW) / 2,
          page.top + ph * .3,
          contentW,
          contentH,
        );
    }
    canvas.drawRect(block, content);
    for (var i = 0; i < 3; i++) {
      final y = block.top + block.height * (.25 + i * .22);
      canvas.drawRect(
        Rect.fromLTWH(block.left + 4, y, block.width - 8, 2),
        lines,
      );
    }
    if (mode == PdfLayoutMode.custom) {
      final p = Paint()
        ..color = AppColors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRect(block, p);
      // freccia doppia verticale: il contenuto si sposta, non cambia misura
      final c = Offset(block.center.dx, block.top - 2);
      canvas.drawLine(c.translate(0, -8), c.translate(0, 0), p);
    }
  }

  @override
  bool shouldRepaint(_MiniPage old) => old.mode != mode;
}
