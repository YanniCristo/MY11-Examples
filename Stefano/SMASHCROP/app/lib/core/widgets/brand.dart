import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';

/// Marchio dell'app: icona di SMASH + scritta SMASHCROP
/// ("SMASH" rosso, "CROP" bianco).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SmashCrop',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(size * .28),
              child: Image.asset(
                'assets/branding/logo_icon.png',
                width: size * 1.3,
                height: size * 1.3,
              ),
            ),
            SizedBox(width: size * .35),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'SMASH',
                    style: TextStyle(color: AppColors.red),
                  ),
                  TextSpan(
                    text: 'CROP',
                    style: TextStyle(color: AppColors.text),
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontWeight: FontWeight.w800,
                fontSize: size,
                height: 1,
                letterSpacing: -.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
