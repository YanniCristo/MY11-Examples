import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../rubble/application/rubble_store.dart';
import '../domain/ink_math.dart';

/// Contatore in alto in modalità OctoSmash: litri d'inchiostro della linea
/// in uso (Bianca = inchiostro nero, Nera = inchiostro bianco) e barra verso
/// il prossimo contenitore. Separato dai kg di macerie.
class InkCounterBar extends StatelessWidget {
  const InkCounterBar({super.key, required this.store, required this.white});

  final RubbleStore store;

  /// `true` se si sta usando l'inchiostro bianco (OctoSmash Nero).
  final bool white;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // un solo contatore: tutti gli inchiostri insieme
        final l = (store.inkWhiteMl + store.inkBlackMl) / 1000;
        final next = InkMath.nextGoal(l);
        final head = 'assets/octo/testa_${white ? 'nero' : 'bianco'}.webp';
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${InkMath.format(l, comma: S.decimalComma)} L',
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Image.asset(head, width: 28, height: 28),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: InkMath.progress(l),
                    minHeight: 10,
                    backgroundColor: const Color(0xFF1C1F27),
                    color: const Color(0xFFB9C2CF),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                next == null ? '★' : InkMath.goalNames[next],
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
