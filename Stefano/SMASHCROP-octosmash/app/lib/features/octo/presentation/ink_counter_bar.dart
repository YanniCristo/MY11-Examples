import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../rubble/application/rubble_store.dart';
import '../domain/ink_math.dart';
import '../domain/octo_chars.dart';

const _grey = ColorFilter.matrix([
  .3, .5, .2, 0, 0, //
  .3, .5, .2, 0, 0,
  .3, .5, .2, 0, 0,
  0, 0, 0, .55, 0,
]);

/// Il contatore dell'inchiostro, gemello di quello di SMASH: litri, testa
/// dell'OctoSmash in uso, barra verso la prossima evoluzione, testa della
/// prossima e freccetta ›. Con OctoSmash che dorme è grigio.
class InkCounterBar extends StatefulWidget {
  const InkCounterBar({
    super.key,
    required this.store,
    required this.head,
    this.awake = true,
    this.onTap,
    this.headKey,
    this.bump = 0,
  });

  /// Sulla testa: lì arrivano le gocce d'inchiostro.
  final GlobalKey? headKey;

  /// Cambia a ogni goccia arrivata: la testa fa un piccolo saltello.
  final int bump;

  /// Tocco: apre la Collezione di OctoSmash.
  final VoidCallback? onTap;

  /// OctoSmash sveglio (spento: testa che dorme, contatore grigio).
  final bool awake;

  final RubbleStore store;

  /// Testa del personaggio in uso.
  final String head;

  @override
  State<InkCounterBar> createState() => _InkCounterBarState();
}

class _InkCounterBarState extends State<InkCounterBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gainAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late int _ml = _total;
  String _gain = '';

  int get _total => widget.store.inkBlackMl + widget.store.inkWhiteMl;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStore);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _gainAnim.dispose();
    super.dispose();
  }

  void _onStore() {
    final t = _total;
    if (t > _ml) {
      _gain = '+${InkMath.format((t - _ml) / 1000, comma: S.decimalComma)} L';
      _gainAnim.forward(from: 0);
    }
    _ml = t;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final l = _total / 1000;
    final g = InkMath.nextGoal(l);
    final next = g == null
        ? null
        : kOctoChars.where((c) => c.goal == g).firstOrNull;
    final cur = octoCharById(s.octoSkin);
    const head = 30.0;
    final text = '${InkMath.format(l, comma: S.decimalComma)} L';

    final bar = LayoutBuilder(
      builder: (context, c) {
        final p = next == null ? 1.0 : InkMath.progress(l);
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
                colors: [cur.color, next?.color ?? cur.color],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );

    Widget content = Row(
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        TweenAnimationBuilder<double>(
          key: ValueKey(widget.bump),
          tween: Tween(begin: widget.bump == 0 ? 1 : 1.3, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (_, k, child) => Transform.scale(scale: k, child: child),
          child: SizedBox(
            key: widget.headKey,
            width: head,
            height: head,
            child: Image.asset(widget.head, fit: BoxFit.contain),
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
        const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
      ],
    );
    if (!widget.awake) {
      content = ColorFiltered(colorFilter: _grey, child: content);
    }

    return Semantics(
      button: true,
      label: '${S.collection}, $text',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.onTap,
        child: Container(
          height: 40,
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
              // "+0,52 L" che sale e svanisce
              AnimatedBuilder(
                animation: _gainAnim,
                builder: (context, _) {
                  final k = _gainAnim.value;
                  if (k == 0 || k == 1) return const SizedBox.shrink();
                  return Positioned(
                    left: 0,
                    top: -6 - 18 * k,
                    child: Opacity(
                      opacity: (1 - k).clamp(0.0, 1.0),
                      child: Text(
                        _gain,
                        style: const TextStyle(
                          color: Color(0xFF7FE3FF),
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
