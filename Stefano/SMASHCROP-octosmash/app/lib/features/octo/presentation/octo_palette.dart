import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../rubble/application/rubble_store.dart';

/// Il colore scelto nella tavolozza e da dove viene: quelli presi con la
/// pipetta li spruzza l'OctoSmash Pipetta, gli altri il Multicolor.
typedef PaletteChoice = ({int color, bool picked});

/// Tavolozza di OctoSmash: in alto "I tuoi colori" (prima i fissati con la
/// puntina, poi gli ultimi presi con la pipetta; restano anche chiudendo
/// l'app), poi una griglia di colori scelti bene.
class OctoPalette extends StatefulWidget {
  const OctoPalette({super.key, required this.store});

  final RubbleStore store;

  static const List<int> colors = [
    // pieni
    0xFFE5484D, 0xFFF76B15, 0xFFF5A524, 0xFFF7E15A, 0xFF8BD346, 0xFF30A46C,
    0xFF12A594, 0xFF22B8F2, 0xFF3E63DD, 0xFF6E56CF, 0xFFAB4ABA, 0xFFE54DB5,
    // chiari (sfondi di bollette, evidenziatori)
    0xFFFFE5E5, 0xFFFFEAD6, 0xFFFFF4C2, 0xFFE6F6D9, 0xFFD9F2F7, 0xFFE3E9FF,
    // scuri
    0xFF7A1F22, 0xFF7A3A0E, 0xFF1F5135, 0xFF0D3B66, 0xFF2E1F5E, 0xFF5C1A42,
    // grigi e carta
    0xFFFFFFFF, 0xFFF4F1EA, 0xFFD9D9D9, 0xFF9E9E9E, 0xFF555555, 0xFF000000,
  ];

  @override
  State<OctoPalette> createState() => _OctoPaletteState();
}

class _OctoPaletteState extends State<OctoPalette> {
  RubbleStore get store => widget.store;
  static const colors = OctoPalette.colors;

  /// "Puoi fissare al massimo 6 colori" al posto del suggerimento, per poco.
  bool _full = false;

  void _showFull() {
    HapticFeedback.heavyImpact();
    setState(() => _full = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _full = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(int c, {bool picked = false, bool pinned = false}) =>
        GestureDetector(
          onTap: () =>
              Navigator.of(context)
                  .pop<PaletteChoice>((color: c, picked: picked)),
          onLongPress: !picked
              ? null
              : () {
                  if (store.togglePin(c)) {
                    HapticFeedback.mediumImpact();
                  } else {
                    _showFull();
                  }
                },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(c),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pinned
                          ? const Color(0xCCFFFFFF)
                          : const Color(0x33FFFFFF),
                      width: pinned ? 2 : 1,
                    ),
                  ),
                ),
              ),
              if (pinned)
                const Positioned(
                  right: -5,
                  top: -7,
                  child: Text('📌', style: TextStyle(fontSize: 14)),
                ),
            ],
          ),
        );

    // sempre tutta visibile: tasselli più bassi e, se non basta, si scorre
    return SafeArea(
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final mine = [
            for (final c in store.octoPinned) (c, true),
            for (final c in store.octoRecent) (c, false),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mine.isNotEmpty) ...[
                  Text(
                    S.myColors,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _full ? S.pinFull : S.pinHint,
                    style: TextStyle(
                      color: _full ? AppColors.red : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: _full ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 6,
                    shrinkWrap: true,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final (c, pin) in mine)
                        tile(c, picked: true, pinned: pin),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  S.paletteTitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [for (final c in colors) tile(c)],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
