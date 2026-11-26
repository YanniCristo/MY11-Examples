import 'package:material_ui/material_ui.dart';

/// Marchio dell'app: icona di SMASH + scritta SMASHCROP (immagine presa dal logo).
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
            Image.asset(
              'assets/branding/wordmark.webp',
              height: size * .95,
              filterQuality: FilterQuality.medium,
            ),
          ],
        ),
      ),
    );
  }
}
