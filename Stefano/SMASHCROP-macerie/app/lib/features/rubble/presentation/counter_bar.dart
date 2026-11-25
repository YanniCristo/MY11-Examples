import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../application/rubble_store.dart';
import '../domain/rubble_math.dart';

const _grey = ColorFilter.matrix([
  .3, .5, .2, 0, 0, //
  .3, .5, .2, 0, 0,
  .3, .5, .2, 0, 0,
  0, 0, 0, .55, 0,
]);

/// Il contatore delle macerie: totale in kg, testa dello SMASH in uso,
/// barra verso la prossima evoluzione, testa della prossima (nel suo
/// colore vero) e freccetta ›. Con SMASH spento è grigio e addormentato.
class CounterBar extends StatefulWidget {
  const CounterBar({
    super.key,
    required this.store,
    required this.awake,
    required this.onTap,
    this.headKey,
    this.compact = true,
  });

  final RubbleStore store;
  final bool awake;
  final VoidCallback onTap;

  /// Sulla testa in uso: è il bersaglio dei pezzi raccolti.
  final GlobalKey? headKey;

  /// Versione stretta per la riga in alto dell'editor.
  final bool compact;

  @override
  State<CounterBar> createState() => _CounterBarState();
}

class _CounterBarState extends State<CounterBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late int _tick = widget.store.gainTick;
  String _gain = '';

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void didUpdateWidget(CounterBar old) {
    super.didUpdateWidget(old);
    if (old.store != widget.store) {
      old.store.removeListener(_onStore);
      widget.store.addListener(_onStore);
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _bump.dispose();
    super.dispose();
  }

  void _onStore() {
    final s = widget.store;
    if (s.gainTick != _tick) {
      _tick = s.gainTick;
      _gain = '+${RubbleMath.format(s.lastGainKg, comma: S.decimalComma)} kg';
      _bump.forward(from: 0);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final next = s.nextEvolution;
    final awake = widget.awake;
    final kgText = '${RubbleMath.format(s.kg, comma: S.decimalComma)} kg';
    final h = widget.compact ? 40.0 : 48.0;
    final head = widget.compact ? 30.0 : 38.0;

    Widget bar = LayoutBuilder(
      builder: (context, c) {
        final p = next == null ? 1.0 : s.progress;
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2C36),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: c.maxWidth * p,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [s.skin.color, next?.color ?? s.skin.color],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );

    Widget content = Row(
      children: [
        // con tanti chili il numero si rimpicciolisce, le teste restano
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              kgText,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.text,
                fontSize: widget.compact ? 13 : 16,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _bump,
          builder: (context, child) {
            final k = _bump.value;
            final scale = 1 + .28 * Curves.elasticOut.transform(k) * (1 - k);
            return Transform.scale(scale: scale, child: child);
          },
          child: SizedBox(
            key: widget.headKey,
            width: head,
            height: head,
            child: Image.asset(
              awake ? s.skin.head : s.skin.headSleep,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 14),
            child: bar,
          ),
        ),
        const SizedBox(width: 4),
        if (next != null)
          SizedBox(
            width: head * .8,
            height: head * .8,
            child: Image.asset(next.head, fit: BoxFit.contain),
          ),
        if (!widget.compact) ...[
          const SizedBox(width: 8),
          Text(
            S.collection,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ],
    );
    if (!awake) content = ColorFiltered(colorFilter: _grey, child: content);

    return Semantics(
      button: true,
      label: '${S.collection}, $kgText',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Container(
          height: h,
          padding: const EdgeInsets.only(left: 8, right: 2),
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: content),
              if (s.hasNew && awake)
                Positioned(
                  right: 2,
                  top: 3,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              // "+0,30 kg" che sale e svanisce
              AnimatedBuilder(
                animation: _bump,
                builder: (context, _) {
                  final k = _bump.value;
                  if (k == 0 || k == 1) return const SizedBox.shrink();
                  return Positioned(
                    left: 0,
                    top: -6 - 18 * k,
                    child: Opacity(
                      opacity: (1 - k).clamp(0.0, 1.0),
                      child: Text(
                        _gain,
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(blurRadius: 4)],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
