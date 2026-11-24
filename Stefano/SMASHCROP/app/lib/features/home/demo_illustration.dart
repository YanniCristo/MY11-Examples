import 'package:material_ui/material_ui.dart';

import '../../app/strings.dart';

/// Illustrazione della home: città, fogli e SMASH sono un'immagine; i testi
/// dei fogli li scrive l'app, così cambiano con la lingua.
///
/// Foglio 1: il documento con il pezzo inutile (fascia rosa); foglio 2: lo
/// stesso documento dopo il pugno di SMASH, già ricongiunto.
class DemoIllustration extends StatelessWidget {
  const DemoIllustration({super.key});

  // dimensioni dell'immagine: tutte le posizioni sono in questi pixel
  static const double w = 732, h = 738;

  @override
  Widget build(BuildContext context) {
    final t = _DemoTexts.current;
    return Semantics(
      label: S.demoDescription,
      child: ExcludeSemantics(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/home/home_illustration_blank.webp',
                  fit: BoxFit.fill,
                ),
              ),
              // --- foglio 1 -------------------------------------------------
              _box(77, 138, 249, 36, _title(t.title)),
              _rule(77, 184, 249),
              _box(77, 194, 249, 86, _body(t.intro)),
              // fascia da togliere
              _box(
                77,
                299,
                249,
                17,
                Text(
                  '✂  ${t.band}',
                  style: const TextStyle(
                    color: Color(0xFFD0141A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
              Positioned(left: 77, top: 320, child: _StatsTable(t.rows)),
              Positioned(left: 252, top: 318, child: _StressChart(t.stress)),
              _box(77, 416, 236, 82, _body(t.outro)),
              // --- foglio 2: dopo SMASH ----------------------------------------
              _box(441, 190, 231, 36, _title(t.title)),
              _rule(441, 234, 231),
              _box(441, 243, 231, 84, _body(t.intro)),
              _box(441, 334, 231, 80, _body(t.outro)),
              Positioned(left: 520, top: 392, child: _Stamp(t.stamp)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _box(double l, double tp, double bw, double bh, Widget child) =>
      Positioned(
        left: l,
        top: tp,
        width: bw,
        height: bh,
        // testi più lunghi in alcune lingue: si rimpiccioliscono, mai tagliati
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(width: bw, child: child),
        ),
      );

  static Widget _rule(double l, double tp, double rw) => Positioned(
    left: l,
    top: tp,
    width: rw,
    height: 1.5,
    child: const ColoredBox(color: Color(0xFFD9DCE6)),
  );

  static Widget _title(String s) => Text(
    s,
    maxLines: 1,
    softWrap: false,
    style: const TextStyle(
      color: Color(0xFF151824),
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -.3,
    ),
  );

  static Widget _body(String s) => Text(
    s,
    style: const TextStyle(
      color: Color(0xFF262A36),
      fontSize: 13.5,
      height: 1.32,
    ),
  );
}

class _StatsTable extends StatelessWidget {
  const _StatsTable(this.rows);
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    const border = BorderSide(color: Color(0xFFC9A5AD));
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        border: Border.all(color: const Color(0xFFC9A5AD)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              height: 23,
              decoration: BoxDecoration(
                border: i == 0 ? null : const Border(top: border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rows[i].$1,
                          style: const TextStyle(
                            color: Color(0xFF262A36),
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 23,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(left: border),
                    ),
                    child: Text(
                      rows[i].$2,
                      style: const TextStyle(
                        color: Color(0xFFD0141A),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Grafico dello stress che sale (rosso): il pezzo che SMASH porta via.
class _StressChart extends StatelessWidget {
  const _StressChart(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    Widget bar(double hh, Color c) => Container(
      width: 15,
      height: hh,
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      decoration: BoxDecoration(
        color: c,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
      ),
    );
    return SizedBox(
      width: 70,
      height: 80,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                bar(16, const Color(0xFFF08A8F)),
                bar(34, const Color(0xFFE5464F)),
                bar(58, const Color(0xFFD0141A)),
              ],
            ),
          ),
          Container(height: 1.5, color: const Color(0xFFB98F98)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFD0141A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Timbro rosso storto sul foglio sistemato.
class _Stamp extends StatelessWidget {
  const _Stamp(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.16,
      child: Container(
        width: 148,
        height: 34,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0x14D0141A),
          border: Border.all(color: const Color(0xFFD0141A), width: 2.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD0141A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
        ),
      ),
    );
  }
}

/// Testi dei fogli dimostrativi, uno per lingua.
class _DemoTexts {
  const _DemoTexts({
    required this.title,
    required this.intro,
    required this.band,
    required this.rows,
    required this.stress,
    required this.outro,
    required this.stamp,
  });

  final String title, intro, band, stress, outro, stamp;
  final List<(String, String)> rows;

  static _DemoTexts get current => switch (S.lang) {
    AppLang.it => _it,
    AppLang.en => _en,
    AppLang.fr => _fr,
    AppLang.es => _es,
    AppLang.pt => _pt,
    AppLang.de => _de,
  };

  static const _it = _DemoTexts(
    title: 'Relazione Seriissima',
    intro:
        'Capo, ecco il documento perfetto. Manca solo un dettaglio: '
        'togliere quel pezzo inutile qui sotto.',
    band: 'PEZZO INUTILE',
    rows: [
      ('Ore perse a ritagliare', '3'),
      ('Caffè bevuti', '7'),
      ('Pazienza rimasta', '0%'),
    ],
    stress: 'STRESS',
    outro:
        'Poi è arrivato SMASH: un pugno e il pezzo è sparito. '
        'Il resto si è riunito da solo.',
    stamp: '1 PUGNO, 0 STRESS',
  );

  static const _en = _DemoTexts(
    title: 'Very Serious Report',
    intro:
        'Boss, here\'s the perfect document. Just one detail: '
        'lose that useless bit below.',
    band: 'USELESS BIT',
    rows: [
      ('Hours wasted cropping', '3'),
      ('Coffees drunk', '7'),
      ('Patience left', '0%'),
    ],
    stress: 'STRESS',
    outro:
        'Then SMASH showed up: one punch and it was gone. '
        'The rest joined up by itself.',
    stamp: '1 PUNCH, 0 STRESS',
  );

  static const _fr = _DemoTexts(
    title: 'Rapport Très Sérieux',
    intro:
        'Chef, voici le document parfait. Un seul détail : '
        'virer ce passage inutile ci-dessous.',
    band: 'PASSAGE INUTILE',
    rows: [
      ('Heures perdues', '3'),
      ('Cafés bus', '7'),
      ('Patience restante', '0 %'),
    ],
    stress: 'STRESS',
    outro:
        'Puis SMASH est arrivé : un coup de poing et hop, disparu. '
        'Le reste s\'est recollé tout seul.',
    stamp: '1 POING, 0 STRESS',
  );

  static const _es = _DemoTexts(
    title: 'Informe Seriísimo',
    intro:
        'Jefe, aquí tiene el documento perfecto. Solo falta un detalle: '
        'quitar ese trozo inútil de abajo.',
    band: 'TROZO INÚTIL',
    rows: [
      ('Horas perdidas', '3'),
      ('Cafés tomados', '7'),
      ('Paciencia restante', '0 %'),
    ],
    stress: 'ESTRÉS',
    outro:
        'Entonces llegó SMASH: un puñetazo y adiós trozo. '
        'El resto se unió solo.',
    stamp: '1 PUÑETAZO, 0 ESTRÉS',
  );

  static const _pt = _DemoTexts(
    title: 'Relatório Seríssimo',
    intro:
        'Chefe, aqui está o documento perfeito. Só falta um detalhe: '
        'tirar aquele pedaço inútil aí embaixo.',
    band: 'PEDAÇO INÚTIL',
    rows: [
      ('Horas perdidas', '3'),
      ('Cafés tomados', '7'),
      ('Paciência restante', '0%'),
    ],
    stress: 'ESTRESSE',
    outro:
        'Aí chegou o SMASH: um soco e o pedaço sumiu. '
        'O resto se juntou sozinho.',
    stamp: '1 SOCO, 0 ESTRESSE',
  );

  static const _de = _DemoTexts(
    title: 'Todernster Bericht',
    intro:
        'Chef, hier ist das perfekte Dokument. Nur ein Detail fehlt: '
        'das nutzlose Stück unten muss weg.',
    band: 'NUTZLOSES STÜCK',
    rows: [
      ('Verlorene Stunden', '3'),
      ('Getrunkene Kaffees', '7'),
      ('Restgeduld', '0 %'),
    ],
    stress: 'STRESS',
    outro:
        'Dann kam SMASH: ein Faustschlag, und weg war es. '
        'Der Rest hat sich von selbst zusammengefügt.',
    stamp: '1 SCHLAG, 0 STRESS',
  );
}
