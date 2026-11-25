/// Direzione del taglio.
///
/// [horizontal]: la fascia attraversa tutta la larghezza, si eliminano righe.
/// [vertical]: la fascia attraversa tutta l'altezza, si eliminano colonne.
enum CutOrientation { horizontal, vertical }

/// Un taglio registrato nella cronologia.
///
/// [start] e [end] sono espressi in pixel del documento *così com'era*
/// prima di questo taglio, con `start < end`. Il taglio elimina l'intervallo
/// semiaperto `[start, end)` e ricongiunge ciò che resta.
class CutOperation {
  const CutOperation({
    required this.orientation,
    required this.start,
    required this.end,
    required this.lengthBefore,
  });

  final CutOrientation orientation;
  final int start;
  final int end;

  /// Altezza (taglio orizzontale) o larghezza (verticale) prima del taglio.
  final int lengthBefore;

  int get removed => end - start;
  int get lengthAfter => lengthBefore - removed;

  /// Costruisce un taglio dalle coordinate delle due linee A e B.
  ///
  /// A e B possono essere in qualsiasi ordine. Restituisce `null` se il
  /// taglio non è valido: fascia di ampiezza nulla, oppure un taglio che
  /// lascerebbe il documento senza pixel.
  static CutOperation? fromLines({
    required CutOrientation orientation,
    required double a,
    required double b,
    required int length,
  }) {
    if (length <= 1) return null;
    final lo = (a < b ? a : b).round().clamp(0, length);
    final hi = (a < b ? b : a).round().clamp(0, length);
    if (hi - lo < 1) return null;
    if (length - (hi - lo) < 1) return null;
    return CutOperation(
      orientation: orientation,
      start: lo,
      end: hi,
      lengthBefore: length,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CutOperation &&
      other.orientation == orientation &&
      other.start == start &&
      other.end == end &&
      other.lengthBefore == lengthBefore;

  @override
  int get hashCode => Object.hash(orientation, start, end, lengthBefore);

  @override
  String toString() =>
      'CutOperation(${orientation.name}, $start..$end of $lengthBefore)';
}
