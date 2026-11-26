/// Litri d'inchiostro di OctoSmash: si contano dalla superficie coperta.
class InkMath {
  /// Pixel del documento coperti da un litro.
  static const double pxPerLitre = 250000;

  static double litres(double areaPx) => areaPx / pxPerLitre;

  /// I 4 contenitori, uno per evoluzione come per SMASH (litri).
  static const goals = [5.0, 50.0, 200.0, 1000.0];
  static const goalNames = ['Calamaio', 'Tanica', 'Bidone', 'Autocisterna'];

  /// Indice del prossimo contenitore, o `null` se sono tutti pieni.
  static int? nextGoal(double l) {
    for (var i = 0; i < goals.length; i++) {
      if (l < goals[i]) return i;
    }
    return null;
  }

  /// Avanzamento 0–1 verso il prossimo contenitore.
  static double progress(double l) {
    final i = nextGoal(l);
    if (i == null) return 1;
    final from = i == 0 ? 0.0 : goals[i - 1];
    return ((l - from) / (goals[i] - from)).clamp(0.0, 1.0);
  }

  static String format(double l, {required bool comma}) {
    final s = l < 10 ? l.toStringAsFixed(2) : l.toStringAsFixed(1);
    return comma ? s.replaceAll('.', ',') : s;
  }
}
