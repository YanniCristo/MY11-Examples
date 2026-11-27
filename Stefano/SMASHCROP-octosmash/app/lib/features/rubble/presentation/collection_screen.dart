import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/close_square_button.dart';
import '../../premium/lifetime_sheet.dart';
import '../application/rubble_store.dart';
import '../application/sound_fx.dart';
import '../domain/rubble_math.dart';
import '../domain/skins.dart';
import '../../octo/presentation/octo_collection_screen.dart';
import 'share_card.dart';
import 'skin_player.dart';

/// La Collezione degli SMASH: anteprima animata in alto, griglia sotto.
/// Le sbloccate si toccano per vederle e indossarle; le altre mostrano la
/// sagoma, il lucchetto e quanto manca.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.store,
    this.highlight,
    this.afterEvolution = false,
  });

  final RubbleStore store;

  /// Skin da mostrare all'apertura (per esempio quella appena sbloccata).
  final SkinDef? highlight;

  /// Aperta dopo un'evoluzione: in basso c'è "Continua a tagliare".
  final bool afterEvolution;

  static Future<void> open(
    BuildContext context,
    RubbleStore store, {
    SkinDef? highlight,
    bool afterEvolution = false,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CollectionScreen(
          store: store,
          highlight: highlight,
          afterEvolution: afterEvolution,
        ),
      ),
    );
  }

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late SkinDef _sel = widget.highlight ?? widget.store.skin;
  int _play = 0;
  late final Set<String> _newOnes = {
    for (final id in widget.store.unlocked)
      if (!widget.store.seen.contains(id)) id,
  };
  final _shareKey = GlobalKey();

  RubbleStore get s => widget.store;

  @override
  void initState() {
    super.initState();
    s.addListener(_changed);
    if (s.sound && s.isUnlocked(_sel)) SoundFx.instance.prepare(_sel);
    // aprendo la Collezione le novità sono viste
    WidgetsBinding.instance.addPostFrameCallback((_) => s.markSeen());
  }

  @override
  void dispose() {
    s.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _select(SkinDef k) {
    if (s.sound && s.isUnlocked(k)) SoundFx.instance.prepare(k);
    setState(() {
      _sel = k;
      _play++;
    });
  }

  String _status(SkinDef k) {
    if (k.unlock == Unlock.lifetime) return S.lockedLifetime;
    final miss = RubbleMath.missing(s.kg, k);
    return '${k.goalLabel} · ${S.missingKg(RubbleMath.format(miss, comma: S.decimalComma))}';
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = s.isUnlocked(_sel);
    final inUse = s.skinId == _sel.id;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    S.collection,
                    style: TextStyle(
                      fontFamily: kDisplayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 🔄 SMASH ↔ OctoSmash (cambia solo la vista)
                  SizedBox(
                    height: 36,
                    child: AppButton(
                      label: 'Octo',
                      icon: const Icon(Icons.sync),
                      height: 36,
                      fontSize: 13,
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => OctoCollectionScreen(store: s),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${RubbleMath.format(s.kg, comma: S.decimalComma)} kg',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CloseSquareButton(onTap: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: RadialGradient(
                      colors: [
                        _sel.color.withValues(alpha: unlocked ? .38 : .12),
                        AppColors.surface,
                      ],
                      radius: .9,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 64),
                          child: SkinPlayer(
                            skin: _sel,
                            playId: _play,
                            locked: !unlocked,
                            // il suo verso nel momento del colpo
                            onImpact: () {
                              if (s.sound) SoundFx.instance.hit(_sel);
                            },
                          ),
                        ),
                      ),
                      // l'obiettivo (carriola, betoniera...) bello grande
                      if (_sel.goalImage != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Transform.rotate(
                            angle: -.12,
                            child: Opacity(
                              opacity: unlocked ? 1 : .9,
                              child: Image.asset(
                                _sel.goalImage!,
                                width: 92,
                                height: 92,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Column(
                          children: [
                            Text(
                              _sel.name,
                              style: TextStyle(
                                fontFamily: kDisplayFont,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: unlocked ? _sel.color : AppColors.text,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!unlocked) ...[
                                  const Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    unlocked
                                        ? _sel.goalDoneLabel
                                        : _status(_sel),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: !unlocked && _sel.unlock == Unlock.lifetime
                        ? AppButton(
                            label: S.unlockWithLifetime,
                            icon: const Icon(Icons.workspace_premium),
                            style: AppButtonStyle.primary,
                            height: 48,
                            fontSize: 15,
                            onPressed: () => showLifetimeSheet(context),
                          )
                        : AppButton(
                            label: inUse ? S.inUse : S.useSkin,
                            icon: Icon(inUse ? Icons.check : Icons.bolt),
                            style: inUse
                                ? AppButtonStyle.secondary
                                : AppButtonStyle.primary,
                            height: 48,
                            fontSize: 16,
                            onPressed: unlocked && !inUse
                                ? () => s.choose(_sel)
                                : null,
                          ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    key: _shareKey,
                    width: 52,
                    child: AppButton(
                      label: '',
                      semanticLabel: S.shareCard,
                      icon: const Icon(Icons.ios_share),
                      height: 48,
                      onPressed: unlocked ? _share : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 4,
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: .92,
                  children: [for (final k in kSkins) _card(k)],
                ),
              ),
              if (widget.afterEvolution) ...[
                const SizedBox(height: 8),
                AppButton(
                  label: S.continueCutting,
                  icon: const Icon(Icons.content_cut),
                  style: AppButtonStyle.primary,
                  height: 50,
                  fontSize: 17,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    try {
      await ShareCard.share(
        _sel,
        s.kg,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {}
  }

  Widget _card(SkinDef k) {
    final open = s.isUnlocked(k);
    final sel = _sel.id == k.id;
    final inUse = s.skinId == k.id;
    return Semantics(
      button: true,
      selected: sel,
      label: k.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _select(k);
          if (k.unlock == Unlock.lifetime && !s.isUnlocked(k)) {
            showLifetimeSheet(context);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sel ? (open ? k.color : AppColors.text) : AppColors.border,
              width: sel ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 18,
                child: open
                    ? Image.asset(k.head, fit: BoxFit.contain)
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF0B0C11),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(k.head, fit: BoxFit.contain),
                      ),
              ),
              if (k.goalImage != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image.asset(k.goalImage!, width: 34, height: 34),
                ),
              if (!open)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Icon(
                      Icons.lock,
                      size: 22,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Text(
                  k.name.replaceFirst('SMASH ', ''),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: open ? AppColors.text : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (inUse)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: k.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (_newOnes.contains(k.id))
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      S.newBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
