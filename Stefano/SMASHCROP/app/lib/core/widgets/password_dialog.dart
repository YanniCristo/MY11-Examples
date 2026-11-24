import 'package:material_ui/material_ui.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';

/// Chiede la password di un PDF protetto. `null` se l'utente annulla.
Future<String?> askPdfPassword(BuildContext context, {required bool wrong}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      void submit() => Navigator.pop(context, controller.text);
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(S.passwordTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              wrong ? S.passwordWrong : S.passwordBody,
              style: TextStyle(
                color: wrong ? AppColors.redLight : AppColors.textMuted,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(hintText: S.passwordHint),
              onSubmitted: (_) => submit(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(S.cancel),
          ),
          TextButton(onPressed: submit, child: const Text(S.open)),
        ],
      );
    },
  ).whenComplete(controller.dispose);
}
