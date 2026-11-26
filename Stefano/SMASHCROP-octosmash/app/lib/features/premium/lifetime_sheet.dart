import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/widgets/close_square_button.dart';
import '../rubble/domain/skins.dart';
import '../rubble/presentation/skin_player.dart';
import 'premium.dart';

/// Arancione di SMASH Tycoon: il colore dell'acquisto a vita.
const kLifetimeColor = Color(0xFFEF6C00);

/// La schermata di acquisto di "SmashCrop a vita", la stessa da ogni punto
/// (bottoncino della home, Tycoon nella Collezione, menu, invito dopo il
/// primo salvataggio). [intro] è una riga sopra il titolo, per l'invito.
Future<void> showLifetimeSheet(BuildContext context, {String? intro}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _LifetimeSheet(intro: intro),
  );
}

class _LifetimeSheet extends StatefulWidget {
  const _LifetimeSheet({this.intro});
  final String? intro;

  @override
  State<_LifetimeSheet> createState() => _LifetimeSheetState();
}

class _LifetimeSheetState extends State<_LifetimeSheet> {
  final p = Premium.instance;
  StreamSubscription<PremiumEvent>? _sub;
  String? _note;
  bool _thanks = false;

  @override
  void initState() {
    super.initState();
    p.addListener(_refresh);
    unawaited(p.start());
    _sub = p.events.listen((e) {
      if (!mounted) return;
      setState(() {
        switch (e) {
          case PremiumEvent.purchased:
            _thanks = true;
            _note = null;
          case PremiumEvent.restored:
            _note = S.purchaseRestored;
          case PremiumEvent.nothingToRestore:
            _note = S.nothingToRestore;
          case PremiumEvent.error:
            _note = S.purchaseError;
          case PremiumEvent.unavailable:
            _note = p.canBuy ? S.purchaseError : S.buyOnlyInApp;
        }
      });
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    p.removeListener(_refresh);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final owned = p.owned;
    final price = p.price;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CloseSquareButton(onTap: () => Navigator.pop(context)),
            ),
            // l'animazione intera; mentre carica la posa con l'elmo dritto
            SizedBox(
              height: 170,
              child: AspectRatio(
                aspectRatio: 730 / 470,
                child: SkinPlayer(
                  skin: skinById('tycoon'),
                  placeholder: 'assets/rubble/tycoon/premium.webp',
                  // a riposo: pose scelte da Stefano (atlante 4 e 14)
                  restFrames: (4, 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.intro != null && !owned)
              Text(
                widget.intro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                ),
              ),
            Text(
              S.lifetimeName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kDisplayFont,
                fontWeight: FontWeight.w800,
                fontSize: 26,
                color: kLifetimeColor,
              ),
            ),
            const SizedBox(height: 14),
            _Perk(icon: Icons.block, text: S.lifetimeNoAds),
            const SizedBox(height: 8),
            _Perk(icon: Icons.star_rounded, text: S.lifetimeTycoon),
            const SizedBox(height: 14),
            if (owned || _thanks)
              Text(
                _thanks ? S.lifetimeThanks : S.lifetimeOwned,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )
            else ...[
              Text(
                S.lifetimeOnce,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kLifetimeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: p.busy ? null : p.buy,
                  child: p.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          price == null ? S.buy : S.buyFor(price),
                          style: TextStyle(
                            fontFamily: kDisplayFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: p.busy ? null : p.restore,
                child: Text(
                  S.restorePurchases,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
            if (_note != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _note!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: kLifetimeColor.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: kLifetimeColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.text, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

/// Il bottoncino arancione della home ("👑 A vita"). Sparisce quando
/// l'acquisto è fatto.
class LifetimeChip extends StatelessWidget {
  const LifetimeChip({super.key, required this.listenable});
  final Listenable listenable;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        if (Premium.instance.owned) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Semantics(
            button: true,
            label: S.lifetimeName,
            child: DecoratedBox(
              // oro: sfumatura metallica con testo scuro
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE89A),
                    Color(0xFFF5C542),
                    Color(0xFFD99A16),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x55F5C542), blurRadius: 10),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => showLifetimeSheet(context),
                  child: SizedBox(
                    height: 32,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            size: 15,
                            color: Color(0xFF3A2600),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            S.lifetimeChip,
                            style: TextStyle(
                              fontFamily: kDisplayFont,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: const Color(0xFF3A2600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
