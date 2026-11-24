import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';

/// Oltre questa soglia, nel browser, si avvisa prima di aprire un PDF: il
/// browser del telefono concede poca memoria a una pagina web.
int get largePdfThreshold {
  final mobile =
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
  return (mobile ? 150 : 500) << 20;
}

/// Solo nel browser e solo per file oltre la soglia: chiede se aprire
/// comunque. Non blocca mai: la scelta resta all'utente.
Future<bool> confirmLargePdf(BuildContext context, int bytes) async {
  if (!kIsWeb || bytes < largePdfThreshold) return true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(S.largeTitle),
      content: Text(
        S.largeBody((bytes / (1 << 20)).round()),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(S.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(S.openAnyway),
        ),
      ],
    ),
  );
  return ok ?? false;
}
