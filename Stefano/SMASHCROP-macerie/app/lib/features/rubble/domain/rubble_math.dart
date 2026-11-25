import 'dart:math' as math;

import '../../editor/domain/cut_operation.dart';
import 'skins.dart';

/// Conti delle macerie.
///
/// Un taglio toglie una superficie; con uno spessore fisso del blocco
/// (5 cm) diventa un volume, e con la densità delle macerie da cantiere
/// (1,5 kg al litro) un peso.
class RubbleMath {
  const RubbleMath._();

  static const double blockMm = 50;
  static const double kgPerLitre = 1.5;

  /// Millimetri per pixel delle immagini (stima a 96 dpi).
  static const double imageMmPerPx = 25.4 / 96;

  /// Millimetri per punto PDF (1/72 di pollice).
  static const double pdfMmPerPt = 25.4 / 72;

  /// Chili di un taglio. [crossPx] è la misura della fascia sull'altro asse
  /// (la larghezza per un taglio orizzontale), [mmPerPx] quanto vale un
  /// pixel di lavoro.
  static double kgOf(CutOperation op, int crossPx, double mmPerPx) {
    final areaMm2 = op.removed * crossPx * mmPerPx * mmPerPx;
    final litres = areaMm2 * blockMm / 1e6;
    return litres * kgPerLitre;
  }

  /// Il totale con al massimo 3 cifre (4 solo oltre i 999 kg):
  /// 0,30 → 1,25 → 12,4 → 150 → 1.500.
  static String format(double kg, {required bool comma}) {
    String s;
    if (kg < 10) {
      s = kg.toStringAsFixed(2);
    } else if (kg < 100) {
      s = kg.toStringAsFixed(1);
    } else {
      final n = kg.floor();
      s = n.toString();
      if (n >= 1000) {
        final t = s.length - 3;
        s = '${s.substring(0, t)}${comma ? '.' : ','}${s.substring(t)}';
      }
      return s;
    }
    return comma ? s.replaceAll('.', ',') : s;
  }

  /// Avanzamento (0–1) verso la prossima evoluzione, partendo dalla
  /// soglia precedente. 1 se sono già tutte sbloccate.
  static double progress(double kg) {
    var from = 0.0;
    for (final e in kEvolutions) {
      if (kg < e.thresholdKg) {
        return ((kg - from) / (e.thresholdKg - from)).clamp(0.0, 1.0);
      }
      from = e.thresholdKg;
    }
    return 1;
  }

  /// La prossima evoluzione da sbloccare, o `null` se sono tutte fatte.
  static SkinDef? next(double kg) {
    for (final e in kEvolutions) {
      if (kg < e.thresholdKg) return e;
    }
    return null;
  }

  /// Evoluzioni raggiunte passando da [before] ad [after] chili.
  static List<SkinDef> crossed(double before, double after) => [
    for (final e in kEvolutions)
      if (before < e.thresholdKg && after >= e.thresholdKg) e,
  ];

  /// Tappe (senza evoluzione) raggiunte passando da [before] ad [after].
  static List<String> milestones(double before, double after) => [
    for (final (kg, what) in kMilestones)
      if (before < kg && after >= kg) what,
  ];

  /// Chili che mancano a [skin].
  static double missing(double kg, SkinDef skin) =>
      math.max(0, skin.thresholdKg - kg);
}
