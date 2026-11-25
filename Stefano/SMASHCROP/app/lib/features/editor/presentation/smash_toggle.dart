import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';

/// Controllo SMASH: testa del robot + interruttore. La scritta "SMASH"
/// compare solo se c'è spazio: su un telefono normale resta la testa, che
/// è riconoscibile da sola e non viene tagliata.
class SmashToggle extends StatelessWidget {
  const SmashToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 44,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: S.smash,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.button,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: value ? AppColors.red : AppColors.border,
                width: value ? 1.6 : 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final showLabel = c.maxWidth >= 118;
                return Row(
                  children: [
                    // acceso: SMASH sveglio; spento: SMASH che dorme. Le due
                    // immagini restano caricate entrambe, così il cambio è
                    // immediato e non lampeggia.
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: value ? 1 : 0,
                            child: Image.asset(
                              'assets/branding/smash_face.png',
                            ),
                          ),
                          Opacity(
                            opacity: value ? 0 : .85,
                            child: Image.asset(
                              'assets/branding/smash_face_sleep.png',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 5),
                      const Flexible(
                        child: Text(
                          S.smash,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _MiniSwitch(value: value),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 42,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.red : const Color(0xFF4A4E57),
        borderRadius: BorderRadius.circular(13),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 150),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
