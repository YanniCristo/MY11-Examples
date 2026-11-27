import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/close_square_button.dart';
import '../../premium/lifetime_sheet.dart';
import '../../rubble/application/rubble_store.dart';
import '../../rubble/application/sound_fx.dart';
import '../../rubble/presentation/collection_screen.dart';
import '../domain/ink_math.dart';
import '../domain/octo_chars.dart';
import 'fusion_scene.dart';
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
    OctoFrames.ensure(_sel.isSquad ? 'bianco' : _sel.id);
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
    return 'Riempi ${c.goalWithArticle} · mancano '
        '${InkMath.format(miss.toDouble(), comma: S.decimalComma)} L';
  }

  String _done(OctoChar c) {
    if (c.isSquad) {
      return 'Bianco, Nero, Pipetta e Multicolor: ognuno col suo tasto';
    }
    if (c.lifetime) return S.lifetimeName;
    return 'Hai riempito ${c.goalWithArticle} · fa tutto lui';
  }

  /// Scelta di un OctoSmash: la prima volta che si usa Fusione si vede la
  /// scena dei 4 che si uniscono.
  Future<void> _use() async {
    final id = _sel.id;
    if (id == 'fusione' && !s.fusionSeen) {
      await FusionScene.show(context);
      s.markFusionSeen();
    }
    s.chooseOcto(id);
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
                      // Fusione: si può rivedere la scena della fusione
                      if (_sel.id == 'fusione' && open)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: AppButton(
                            label: 'Fusione',
                            icon: const Icon(Icons.replay),
                            height: 32,
                            fontSize: 12,
                            onPressed: () => FusionScene.show(context),
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
                      onPressed: open && !inUse ? _use : null,
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
      // la foto di gruppo dei 4 di base
      head = Image.asset(
        'assets/octo/teste/squadra_posa.webp',
        fit: BoxFit.contain,
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
  int _startedAt = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => setState(() => _ms = e.inMilliseconds))
      ..start();
  }

  // come SMASH: fa una volta tutta l'animazione, poi resta a riposo
  // dondolando tra due fotogrammi (il 14 e il 15) ogni 0,6 secondi
  static const _fd = 100; // 10 fotogrammi al secondo
  static const _restA = 13, _restB = 14;
  static const _squad = [
    ('bianco', 0xFF000000),
    ('nero', 0xFFFFFFFF),
    ('pipetta', 0xFF22B8F2),
    ('multicolor', 0xFFF7E15A),
  ];

  int _soundDone = -1;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Un tocco: l'animazione riparte da capo.
  void _replay() => setState(() {
    _startedAt = _ms;
    _soundDone = -1;
  });

  // il suono dello spruzzo, una volta per ogni personaggio che spruzza
  void _sound(int k, String line) {
    if (k <= _soundDone) return;
    _soundDone = k;
    if (RubbleStore.instance.sound) SoundFx.instance.octo(line);
  }

  @override
  Widget build(BuildContext context) {
    final t = _ms - _startedAt;
    // la Squadra: i 4 spruzzano uno dopo l'altro (i primi 3 escono di
    // scena, l'ultimo resta); un'evoluzione: lei sola, col suo colore
    final cast = widget.char.isSquad
        ? _squad
        : [(widget.char.id, widget.char.color.toARGB32())];
    const full = OctoFrames.count * _fd; // con l'uscita
    const toRest = (_restA) * _fd; // fino al riposo
    var k = cast.length - 1;
    var local = t - (cast.length - 1) * full;
    if (t < (cast.length - 1) * full) {
      k = t ~/ full;
      local = t % full;
    }
    final (line, ink) = cast[k];
    final last = k == cast.length - 1;
    final int frame;
    if (!last || local < toRest) {
      frame = (local ~/ _fd).clamp(0, OctoFrames.count - 1);
    } else {
      frame = ((local - toRest) ~/ 600).isEven ? _restA : _restB;
    }

    // il prossimo della Squadra si prepara mentre spruzza questo
    if (!last) {
      final next = cast[k + 1].$1;
      if (OctoFrames.line(next) == null) OctoFrames.ensure(next);
    }
    final l = OctoFrames.line(line);
    if (l == null) {
      OctoFrames.ensure(line);
      SoundFx.instance.prepareOctoLine(line);
      // si aspetta che arrivi prima di partire
      _startedAt = _ms - (t < 0 ? 0 : (k * full));
      // intanto, come SMASH, si vede subito la posa da eroe
      if (k == 0) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/octo/teste/${widget.char.isSquad ? 'squadra' : line}'
            '_posa.webp',
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        );
      }
    } else if (frame >= 5 && local < toRest) {
      _sound(k, line);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _replay,
      child: CustomPaint(
        painter: _PreviewPainter(line: l, frame: frame, color: Color(ink)),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({
    required this.line,
    required this.frame,
    required this.color,
  });
  final OctoLine? line;
  final int frame;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final l = line;
    if (l == null) return;
    // personaggio grande (come SMASH nella sua Collezione): il corpo occupa
    // gran parte dell'altezza, entrata e uscita escono dai bordi
    canvas.clipRect(Offset.zero & size);
    final s = size.height * .72 / OctoFrames.bodyH;
    final w = 730 * s, h = 470 * s;
    l.draw(
      canvas,
      frame,
      Rect.fromLTWH(
        (size.width - w) / 2,
        size.height * .92 - OctoFrames.feetY * s,
        w,
        h,
      ),
      color,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.line != line || old.frame != frame || old.color != color;
}
