import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../rubble/application/rubble_store.dart';

/// Popup "Novità: OctoSmash!", mostrato una volta sola.
abstract final class OctoNews {
  static Future<void> maybeShow(BuildContext context) async {
    final s = RubbleStore.instance;
    if (s.octoNewsSeen) return;
    s.markOctoNewsSeen();
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/octo/novita.webp', fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      S.octoNewsTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.octoNewsBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'OK',
                      style: AppButtonStyle.primary,
                      height: 46,
                      fontSize: 16,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
