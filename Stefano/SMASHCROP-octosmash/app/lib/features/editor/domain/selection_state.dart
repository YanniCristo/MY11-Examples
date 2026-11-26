import 'cut_operation.dart';

/// Posizione delle due linee A e B, in pixel del documento.
class LinePair {
  const LinePair(this.a, this.b);
  final double a;
  final double b;

  double get low => a < b ? a : b;
  double get high => a < b ? b : a;

  LinePair withA(double v) => LinePair(v, b);
  LinePair withB(double v) => LinePair(a, v);

  bool fits(int length) => a >= 0 && b >= 0 && a <= length && b <= length;

  /// Posizione iniziale: una fascia utile al centro del documento.
  factory LinePair.initial(CutOrientation o, int length) =>
      o == CutOrientation.horizontal
      ? LinePair((length * .42).roundToDouble(), (length * .56).roundToDouble())
      : LinePair(
          (length * .40).roundToDouble(),
          (length * .60).roundToDouble(),
        );

  @override
  bool operator ==(Object other) =>
      other is LinePair && other.a == a && other.b == b;
  @override
  int get hashCode => Object.hash(a, b);
}

/// Stato della selezione: orizzontale, verticale o nascosta.
///
/// I pulsanti Orizzontale e Verticale sono anche interruttori di
/// visibilità: premendo quello già attivo la selezione si nasconde, premendolo
/// di nuovo torna con le coordinate precedenti (se ancora valide).
class SelectionState {
  const SelectionState({
    required this.mode,
    required this.lastMode,
    required this.lines,
  });

  factory SelectionState.initial({required int width, required int height}) =>
      SelectionState(
        mode: CutOrientation.horizontal,
        lastMode: CutOrientation.horizontal,
        lines: {
          CutOrientation.horizontal: LinePair.initial(
            CutOrientation.horizontal,
            height,
          ),
          CutOrientation.vertical: LinePair.initial(
            CutOrientation.vertical,
            width,
          ),
        },
      );

  /// `null` quando la selezione è nascosta.
  final CutOrientation? mode;
  final CutOrientation lastMode;
  final Map<CutOrientation, LinePair> lines;

  bool get isVisible => mode != null;
  LinePair? get active => mode == null ? null : lines[mode];

  SelectionState tap(
    CutOrientation o, {
    required int width,
    required int height,
  }) {
    if (mode == o) {
      return SelectionState(mode: null, lastMode: o, lines: lines);
    }
    return SelectionState(
      mode: o,
      lastMode: o,
      lines: lines,
    ).ensureValid(width: width, height: height);
  }

  SelectionState withLines(CutOrientation o, LinePair p) =>
      SelectionState(mode: mode, lastMode: lastMode, lines: {...lines, o: p});

  /// Riporta in posizione iniziale le linee che non stanno più nel documento.
  SelectionState ensureValid({required int width, required int height}) {
    final out = {...lines};
    for (final o in CutOrientation.values) {
      final len = o == CutOrientation.horizontal ? height : width;
      final p = out[o];
      if (p == null || !p.fits(len)) out[o] = LinePair.initial(o, len);
    }
    return SelectionState(mode: mode, lastMode: lastMode, lines: out);
  }

  /// Dopo un taglio: nuova selezione nello stesso orientamento, in una
  /// posizione utile sul documento aggiornato.
  SelectionState afterCut(
    CutOrientation o, {
    required int width,
    required int height,
  }) {
    final len = o == CutOrientation.horizontal ? height : width;
    return SelectionState(
      mode: o,
      lastMode: o,
      lines: {...lines, o: LinePair.initial(o, len)},
    ).ensureValid(width: width, height: height);
  }

  SelectionState hidden() =>
      SelectionState(mode: null, lastMode: lastMode, lines: lines);
  SelectionState shown(CutOrientation o) =>
      SelectionState(mode: o, lastMode: o, lines: lines);
}
