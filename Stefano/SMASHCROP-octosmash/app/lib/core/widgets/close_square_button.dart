import 'package:material_ui/material_ui.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';

/// X di chiusura ben visibile: quadrato stondato rosso con la X bianca.
class CloseSquareButton extends StatelessWidget {
  const CloseSquareButton({super.key, required this.onTap, this.size = 40});
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.close,
      child: Tooltip(
        message: S.close,
        child: Material(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Icon(Icons.close, color: Colors.white, size: size * .6),
            ),
          ),
        ),
      ),
    );
  }
}
