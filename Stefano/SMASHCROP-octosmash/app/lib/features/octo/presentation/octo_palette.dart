import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';

/// Tavolozza di OctoSmash: i colori presi con la pipetta in alto, poi una
/// griglia di colori scelti bene (toni pieni, chiari e scuri, e i grigi).
class OctoPalette extends StatelessWidget {
  const OctoPalette({super.key, required this.recent});

  /// Colori presi con la pipetta (il primo è il più recente).
  final List<int> recent;

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
  Widget build(BuildContext context) {
    Widget dot(int c) => GestureDetector(
      onTap: () => Navigator.of(context).pop(c),
      child: Container(
        decoration: BoxDecoration(
          color: Color(c),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recent.isNotEmpty) ...[
              const Text(
                'Presi con la pipetta',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    for (final c in recent)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(width: 40, child: dot(c)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Text(
              'Tavolozza',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [for (final c in colors) dot(c)],
            ),
          ],
        ),
      ),
    );
  }
}
