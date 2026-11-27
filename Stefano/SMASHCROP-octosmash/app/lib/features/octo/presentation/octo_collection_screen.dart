import 'dart:math' as math;

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
import 'ink_fx.dart';
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
  double _t = 0; // secondi
  double _startedAt = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => setState(() => _t = e.inMicroseconds / 1e6))
      ..start();
    for (final (line, ink) in _cast) {
      InkFx.load(Color(ink));
      SoundFx.instance.prepareOctoLine(line);
    }
  }

  // la Squadra: i 4 spruzzano uno dopo l'altro e poi resta la foto di gruppo;
  // un'evoluzione: lei sola, col suo colore
  static const _squad = [
    ('bianco', 0xFF000000),
    ('nero', 0xFFFFFFFF),
    ('pipetta', 0xFF22B8F2),
    ('multicolor', 0xFFF7E15A),
  ];

  List<(String, int)> get _cast => widget.char.isSquad
      ? _squad
      : [(widget.char.id, widget.char.color.toARGB32())];

  // tempi di ogni personaggio: entra, spruzza, (esce se non è l'ultimo)
  static const _in = .35, _spray = .45, _sprayEnd = 1.35, _turn = 1.7;

  int _soundDone = -1;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Un tocco: si rivede da capo.
  void _replay() => setState(() {
    _startedAt = _t;
    _soundDone = -1;
  });

  @override
  Widget build(BuildContext context) {
    final cast = _cast;
    final t = _t - _startedAt;
    final n = cast.length;
    // quale personaggio è in scena, e da quanto
    var k = (t / _turn).floor().clamp(0, n);
    var local = t - k * _turn;
    final resting = k >= n || (n == 1 && local > _sprayEnd + .25);
    if (k >= n) {
      k = n - 1;
      local = t - (n - 1) * _turn;
    }
    final (line, ink) = cast[k];
    if (!resting && local >= _spray && k > _soundDone) {
      _soundDone = k;
      if (RubbleStore.instance.sound) SoundFx.instance.octo(line);
    }

    // a riposo la Squadra torna in foto di gruppo
    final pose = resting && widget.char.isSquad
        ? 'assets/octo/teste/squadra_posa.webp'
        : 'assets/octo/teste/${line}_posa.webp';

    // movimento del corpo
    double dx = 0, dy = 0, rot = 0, sx = 1, sy = 1, alpha = 1;
    if (resting) {
      // riposo come SMASH: due "posizioni" che si alternano ogni 0,6 s,
      // più un respiro leggero
      final r = t - (n * _turn - (n == 1 ? _turn - _sprayEnd - .25 : 0));
      final two = (r / .6).floor().isEven;
      rot = two ? -.025 : .025;
      dy = two ? 0 : -4;
      final b = math.sin(r * 3) * .015;
      sx = 1 + b;
      sy = 1 - b;
    } else if (local < _in) {
      // entra da sinistra con un rimbalzo
      final e = Curves.easeOutBack.transform(local / _in);
      dx = -1.1 * (1 - e);
      final sq = math.sin(local / _in * math.pi) * .12;
      sx = 1 + sq;
      sy = 1 - sq;
    } else if (local < _sprayEnd) {
      // spruzza: si carica all'indietro, poi rinculo e assestamento
      final s = (local - _in) / (_sprayEnd - _in);
      final charge = local < _spray ? (local - _in) / (_spray - _in) : 0.0;
      final kick = local >= _spray
          ? math.exp(-(local - _spray) * 7) * math.sin((local - _spray) * 30)
          : 0.0;
      rot = -.08 * charge + .06 * kick;
      sx = 1 - .06 * charge + .05 * kick.abs();
      sy = 1 + .06 * charge - .05 * kick.abs();
      dx = -.02 * charge;
      dy = -6 * math.sin(s * math.pi).abs() * (1 - charge);
    } else if (k < n - 1) {
      // esce a destra (tutti tranne l'ultimo)
      final e = Curves.easeIn.transform(
        ((local - _sprayEnd) / (_turn - _sprayEnd)).clamp(0, 1),
      );
      dx = 1.2 * e;
      alpha = 1 - e * .3;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _replay,
      child: LayoutBuilder(
        builder: (context, c) {
          final side = math.min(c.maxWidth, c.maxHeight) * .86;
          final w = resting && widget.char.isSquad ? side * 1.5 : side;
          final poseBox = Rect.fromCenter(
            center: Offset(c.maxWidth / 2, c.maxHeight / 2 + side * .02),
            width: math.min(w, c.maxWidth * .98),
            height: side,
          );
          final tool = _tool[line] ?? const Offset(.8, .15);
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: poseBox.shift(Offset(dx * c.maxWidth, dy)),
                  child: Opacity(
                    opacity: alpha,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.identity()
                        ..rotateZ(rot)
                        ..scaleByDouble(sx, sy, 1, 1),
                      child: Image.asset(
                        pose,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
                if (!resting)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SprayPainter(
                        t: local - _spray,
                        from:
                            poseBox.topLeft +
                            Offset(
                              tool.dx * poseBox.width,
                              tool.dy * poseBox.height,
                            ),
                        color: Color(ink),
                        seed: k,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Da dove esce l'inchiostro in ogni posa (in proporzione all'immagine).
  static const Map<String, Offset> _tool = {
    'bianco': Offset(.76, .16),
    'nero': Offset(.78, .14),
    'pipetta': Offset(.76, .1),
    'multicolor': Offset(.78, .14),
    'fusione': Offset(.8, .1),
    'stampa': Offset(.88, .5),
    'abisso': Offset(.92, .14),
    'diluvio': Offset(.86, .4),
    'imperatore': Offset(.84, .26),
  };
}

/// Lo spruzzo nella Collezione: un getto di gocce che parte dallo strumento
/// verso destra, una macchia che esplode e la scritta fumetto.
class _SprayPainter extends CustomPainter {
  _SprayPainter({
    required this.t,
    required this.from,
    required this.color,
    required this.seed,
  });

  /// Secondi dall'inizio dello spruzzo (negativo: non ancora partito).
  final double t;
  final Offset from;
  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (t < 0 || t > .95) return;
    final fx = InkFx.ready(color);
    if (fx == null) return;
    final tint = fx.tint ? color : null;
    final r = math.Random(seed * 31 + 7);
    // la macchia resta dentro il riquadro, con spazio per la scritta sopra
    final sh = size.shortestSide;
    final splat = Offset(
      math.min(from.dx + size.width * .2, size.width - sh * .2),
      math.max(from.dy + size.height * .1, sh * .36),
    );
    final fade = (1 - (t - .6) / .35).clamp(0.0, 1.0);

    // la macchia che esplode dove arriva il getto
    if (t > .08) {
      final k = Curves.easeOutBack.transform(((t - .08) / .18).clamp(0, 1));
      final s = size.shortestSide * .32 * k;
      canvas.save();
      canvas.translate(splat.dx, splat.dy);
      canvas.rotate(seed * 1.3);
      drawInk(
        canvas,
        fx.blobs[seed % 3],
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        tint: tint,
        opacity: fade,
      );
      canvas.restore();
    }

    // il getto: gocce in fila dallo strumento alla macchia, poi schizzi
    for (var i = 0; i < 22; i++) {
      final d = r.nextDouble() * .25;
      final tt = t - d;
      if (tt < 0) continue;
      final k = (tt / .14).clamp(0.0, 1.0);
      final spread = Offset(
        (r.nextDouble() - .3) * size.width * .35,
        (r.nextDouble() - .6) * size.height * .35,
      );
      final after = math.max(0.0, tt - .14);
      final p =
          Offset.lerp(from, splat, k)! +
          spread * after * 1.6 +
          Offset(0, 260 * after * after);
      final s = size.shortestSide * (.035 + r.nextDouble() * .04);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(tt * 8 * (i.isEven ? 1 : -1));
      drawInk(
        canvas,
        fx.drops[r.nextInt(6)],
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        tint: tint,
        opacity: fade,
      );
      canvas.restore();
    }

    // la scritta fumetto
    final k = Curves.elasticOut.transform((t / .45).clamp(0, 1));
    final w = sh * .4 * k;
    canvas.save();
    canvas.translate(
      math.min(splat.dx, size.width - sh * .23),
      splat.dy - sh * .2,
    );
    canvas.rotate(-.12);
    drawInk(
      canvas,
      fx.words[seed % 4],
      Rect.fromCenter(center: Offset.zero, width: w, height: w / 2),
      opacity: fade,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SprayPainter old) => true;
}
