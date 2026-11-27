import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/close_square_button.dart';
import '../../premium/lifetime_sheet.dart';
import '../../rubble/application/rubble_store.dart';
import '../../rubble/presentation/collection_screen.dart';
import '../domain/ink_math.dart';
import '../domain/octo_chars.dart';
import 'octo_layer.dart';

/// La Collezione di OctoSmash: stessa idea di quella di SMASH (anteprima
/// animata in alto, griglia sotto). Il 🔄 passa alla Collezione di SMASH
/// (cambia solo la vista, mai la modalità dell'app).
class OctoCollectionScreen extends StatefulWidget {
  const OctoCollectionScreen({super.key, required this.store});

  final RubbleStore store;

  static Future<void> open(BuildContext context, RubbleStore store) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OctoCollectionScreen(store: store),
      ),
    );
  }

  @override
  State<OctoCollectionScreen> createState() => _OctoCollectionScreenState();
}

class _OctoCollectionScreenState extends State<OctoCollectionScreen> {
  late OctoChar _sel = octoCharById(widget.store.octoSkin);

  RubbleStore get s => widget.store;
  double get _litres => (s.inkBlackMl + s.inkWhiteMl) / 1000;

  @override
  void initState() {
    super.initState();
    OctoFrames.load();
    s.addListener(_changed);
  }

  @override
  void dispose() {
    s.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool _open(OctoChar c) => octoUnlocked(c, _litres, lifetime: s.lifetime);

  String _status(OctoChar c) {
    if (!c.ready) return 'In arrivo';
    if (c.lifetime) return S.lockedLifetime;
    final miss = (c.litres - _litres).clamp(0, double.infinity);
    return 'Riempi un ${c.goalName} · mancano '
        '${InkMath.format(miss.toDouble(), comma: S.decimalComma)} L';
  }

  String _done(OctoChar c) {
    if (c.isSquad) {
      return 'Bianco, Nero, Pipetta e Multicolor: ognuno col suo tasto';
    }
    if (c.lifetime) return S.lifetimeName;
    return 'Hai riempito un ${c.goalName} · fa tutto lui';
  }

  void _toSmash() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CollectionScreen(store: s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = _open(_sel);
    final inUse = s.octoSkin == _sel.id;
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
                  // 🔄 SMASH ↔ OctoSmash
                  SizedBox(
                    height: 36,
                    child: AppButton(
                      label: 'SMASH',
                      icon: const Icon(Icons.sync),
                      height: 36,
                      fontSize: 13,
                      onPressed: _toSmash,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${InkMath.format(_litres, comma: S.decimalComma)} L',
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
                        _sel.color.withValues(alpha: open ? .38 : .12),
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
                          child: open
                              ? _OctoPreview(key: ValueKey(_sel.id), char: _sel)
                              : Center(
                                  child: _sel.ready
                                      ? ColorFiltered(
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFF0B0C11),
                                            BlendMode.srcIn,
                                          ),
                                          child: Image.asset(
                                            _sel.head,
                                            width: 140,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.help_outline,
                                          size: 110,
                                          color: AppColors.border,
                                        ),
                                ),
                        ),
                      ),
                      // il contenitore che lo sblocca, bello grande
                      if (_sel.goalImage != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Transform.rotate(
                            angle: -.12,
                            child: Image.asset(
                              _sel.goalImage!,
                              width: 92,
                              height: 92,
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
                                color: open ? _sel.color : AppColors.text,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!open) ...[
                                  const Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    open ? _done(_sel) : _status(_sel),
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
              !open && _sel.lifetime && _sel.ready
                  ? AppButton(
                      label: S.unlockWithLifetime,
                      icon: const Icon(Icons.workspace_premium),
                      style: AppButtonStyle.primary,
                      height: 48,
                      fontSize: 15,
                      onPressed: () => showLifetimeSheet(context),
                    )
                  : AppButton(
                      label: inUse ? S.inUse : S.useOcto,
                      icon: Icon(inUse ? Icons.check : Icons.bolt),
                      style: inUse
                          ? AppButtonStyle.secondary
                          : AppButtonStyle.primary,
                      height: 48,
                      fontSize: 16,
                      onPressed: open && !inUse
                          ? () => s.chooseOcto(_sel.id)
                          : null,
                    ),
              const SizedBox(height: 10),
              Expanded(
                flex: 4,
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: .92,
                  children: [for (final c in kOctoChars) _card(c)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(OctoChar c) {
    final open = _open(c);
    final sel = _sel.id == c.id;
    final inUse = s.octoSkin == c.id;
    Widget head;
    if (c.isSquad) {
      // i 4 di base, piccoli, a quadrifoglio
      head = GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          for (final n in const ['bianco', 'nero', 'pipetta', 'multicolor'])
            Image.asset('assets/octo/teste/${n}_testa.webp'),
        ],
      );
    } else if (!c.ready) {
      head = const Icon(Icons.help_outline, size: 40, color: AppColors.border);
    } else {
      head = open
          ? Image.asset(c.head, fit: BoxFit.contain)
          : ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF0B0C11),
                BlendMode.srcIn,
              ),
              child: Image.asset(c.head, fit: BoxFit.contain),
            );
    }
    return Semantics(
      button: true,
      selected: sel,
      label: c.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _sel = c);
          if (c.lifetime && c.ready && !open) showLifetimeSheet(context);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sel ? (open ? c.color : AppColors.text) : AppColors.border,
              width: sel ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: Stack(
            children: [
              Positioned.fill(bottom: 18, child: Center(child: head)),
              if (c.goalImage != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image.asset(c.goalImage!, width: 34, height: 34),
                ),
              if (!open && c.ready)
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
                  c.name.replaceFirst('OctoSmash ', ''),
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
                      color: c.color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
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

/// Anteprima animata: la Squadra fa vedere i 4 a turno, ognuno col suo
/// inchiostro; un'evoluzione spruzza ogni volta un inchiostro diverso
/// (nero, bianco, colori), perché li fa tutti lei.
class _OctoPreview extends StatefulWidget {
  const _OctoPreview({super.key, required this.char});
  final OctoChar char;

  @override
  State<_OctoPreview> createState() => _OctoPreviewState();
}

class _OctoPreviewState extends State<_OctoPreview>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _ms = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => setState(() => _ms = e.inMilliseconds))
      ..start();
  }

  static const _loop = 2200; // 18 fotogrammi + una pausa
  static const _squad = [
    ('bianco', 0xFF000000),
    ('nero', 0xFFFFFFFF),
    ('pipetta', 0xFF22B8F2),
    ('multicolor', 0xFFF7E15A),
  ];
  static const _inks = [0xFF000000, 0xFFFFFFFF, 0xFF3E63DD, 0xFF30A46C];

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final round = _ms ~/ _loop;
    final frame = ((_ms % _loop) ~/ 100).clamp(0, OctoFrames.count - 1);
    final String line;
    final int ink;
    if (widget.char.isSquad) {
      (line, ink) = _squad[round % _squad.length];
    } else {
      line = widget.char.id;
      ink = _inks[round % _inks.length];
    }
    return CustomPaint(
      painter: _PreviewPainter(
        body: OctoFrames.lines[line]?[frame],
        ink: OctoFrames.lines['$line:ink']?[frame],
        color: Color(ink),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({required this.body, required this.ink, required this.color});
  final ui.Image? body, ink;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final b = body;
    if (b == null) return;
    // personaggio grande (come SMASH nella sua Collezione): il corpo occupa
    // gran parte dell'altezza, entrata e uscita escono dai bordi
    canvas.clipRect(Offset.zero & size);
    final s = size.height * .72 / OctoFrames.bodyH;
    final w = 730 * s, h = 470 * s;
    final dst = Rect.fromLTWH(
      (size.width - w) / 2,
      size.height * .92 - OctoFrames.feetY * s,
      w,
      h,
    );
    const src = Rect.fromLTWH(0, 0, 730, 470);
    final p = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(b, src, dst, p);
    final k = ink;
    if (k != null) {
      canvas.drawImageRect(
        k,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.mode(color, BlendMode.modulate),
      );
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.body != body || old.ink != ink || old.color != color;
}
