import 'cut_operation.dart';

/// Un intervallo continuo di indici dell'immagine originale: `[start, end)`.
class IndexRun {
  const IndexRun(this.start, this.end) : assert(end > start);
  final int start;
  final int end;
  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is IndexRun && other.start == start && other.end == end;
  @override
  int get hashCode => Object.hash(start, end);
  @override
  String toString() => '[$start,$end)';
}

/// Un tratto del documento attuale e il punto dell'originale da cui proviene.
class RunSlice {
  const RunSlice(this.current, this.original, this.length);

  /// Posizione nel documento attuale.
  final int current;

  /// Posizione corrispondente nell'immagine originale.
  final int original;
  final int length;

  @override
  String toString() => 'RunSlice(cur $current, orig $original, len $length)';
}

/// Elenco ordinato delle righe (o colonne) originali ancora presenti.
///
/// Ogni taglio a fascia intera elimina soltanto righe (orizzontale) o
/// soltanto colonne (verticale). Qualsiasi sequenza di tagli è quindi
/// descritta da quali righe e quali colonne dell'originale restano, in ordine.
/// Questo permette di mostrare e ricostruire il risultato senza tenere in
/// memoria una copia dei pixel per ogni passaggio.
class IndexRuns {
  const IndexRuns._(this.runs, this.length);

  factory IndexRuns.full(int length) {
    if (length <= 0) throw ArgumentError.value(length, 'length');
    return IndexRuns._([IndexRun(0, length)], length);
  }

  final List<IndexRun> runs;
  final int length;

  /// Elimina l'intervallo `[lo, hi)` espresso in coordinate attuali.
  IndexRuns removeRange(int lo, int hi) {
    if (lo < 0 || hi > length || hi <= lo) {
      throw RangeError('removeRange($lo, $hi) su lunghezza $length');
    }
    final out = <IndexRun>[];
    var pos = 0;
    for (final r in runs) {
      final rStart = pos;
      final rEnd = pos + r.length;
      pos = rEnd;
      // parte prima della fascia
      if (rStart < lo) {
        final keepEnd = (lo < rEnd ? lo : rEnd) - rStart;
        out.add(IndexRun(r.start, r.start + keepEnd));
      }
      // parte dopo la fascia
      if (rEnd > hi) {
        final keepStart = (hi > rStart ? hi : rStart) - rStart;
        out.add(IndexRun(r.start + keepStart, r.end));
      }
    }
    return IndexRuns._(_merge(out), length - (hi - lo));
  }

  /// Tratti originali che compongono l'intervallo attuale `[a, b)`.
  List<RunSlice> slice(int a, int b) {
    final out = <RunSlice>[];
    if (b <= a) return out;
    var pos = 0;
    for (final r in runs) {
      final rStart = pos;
      final rEnd = pos + r.length;
      pos = rEnd;
      if (rEnd <= a) continue;
      if (rStart >= b) break;
      final s = a > rStart ? a : rStart;
      final e = b < rEnd ? b : rEnd;
      out.add(RunSlice(s, r.start + (s - rStart), e - s));
    }
    return out;
  }

  /// Indice originale del pixel attuale [i].
  int originalIndex(int i) {
    final s = slice(i, i + 1);
    if (s.isEmpty) throw RangeError.index(i, this);
    return s.first.original;
  }

  static List<IndexRun> _merge(List<IndexRun> runs) {
    final out = <IndexRun>[];
    for (final r in runs) {
      if (out.isNotEmpty && out.last.end == r.start) {
        out[out.length - 1] = IndexRun(out.last.start, r.end);
      } else {
        out.add(r);
      }
    }
    return out;
  }
}

/// Il documento attuale, descritto come sottoinsieme dell'originale.
class StripDocument {
  const StripDocument({
    required this.originalWidth,
    required this.originalHeight,
    required this.rows,
    required this.cols,
  });

  factory StripDocument.original(int width, int height) => StripDocument(
    originalWidth: width,
    originalHeight: height,
    rows: IndexRuns.full(height),
    cols: IndexRuns.full(width),
  );

  final int originalWidth;
  final int originalHeight;
  final IndexRuns rows;
  final IndexRuns cols;

  int get width => cols.length;
  int get height => rows.length;

  int lengthFor(CutOrientation o) =>
      o == CutOrientation.horizontal ? height : width;

  StripDocument apply(CutOperation op) {
    if (op.lengthBefore != lengthFor(op.orientation)) {
      throw StateError('$op non corrisponde al documento (${width}x$height)');
    }
    return op.orientation == CutOrientation.horizontal
        ? StripDocument(
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            rows: rows.removeRange(op.start, op.end),
            cols: cols,
          )
        : StripDocument(
            originalWidth: originalWidth,
            originalHeight: originalHeight,
            rows: rows,
            cols: cols.removeRange(op.start, op.end),
          );
  }

  /// Rettangoli sorgente (nell'originale) e destinazione (nel documento
  /// attuale) che ricompongono la regione attuale indicata.
  ///
  /// Ogni elemento è `[srcX, srcY, dstX, dstY, w, h]`, tutti in pixel.
  List<List<int>> tiles({int x0 = 0, int y0 = 0, int? x1, int? y1}) {
    final out = <List<int>>[];
    for (final r in rows.slice(y0, y1 ?? height)) {
      for (final c in cols.slice(x0, x1 ?? width)) {
        out.add([
          c.original,
          r.original,
          c.current,
          r.current,
          c.length,
          r.length,
        ]);
      }
    }
    return out;
  }
}
