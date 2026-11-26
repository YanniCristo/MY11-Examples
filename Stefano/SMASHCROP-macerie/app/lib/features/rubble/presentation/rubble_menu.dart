import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_menu.dart';
import '../application/rubble_store.dart';
import '../../premium/lifetime_sheet.dart';
import '../../premium/premium.dart';
import 'collection_screen.dart';

/// Le voci del menu ☰ della versione con le macerie, prima di lingua e
/// "Condividi l'app".
List<MenuSection> rubbleMenuSections(BuildContext context, RubbleStore s) {
  void info(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            body,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.close),
          ),
        ],
      ),
    );
  }

  return [
    MenuSection(title: 'SMASH', [
      MenuEntry(
        icon: Icons.collections_outlined,
        label: S.collection,
        onTap: () {
          Navigator.pop(context);
          CollectionScreen.open(context, s);
        },
      ),
      MenuEntry(
        icon: Icons.volume_up_outlined,
        label: S.sounds,
        toggle: s.sound,
        onToggle: s.setSound,
      ),
      MenuEntry(
        icon: Icons.vibration,
        label: S.vibration,
        toggle: s.haptics,
        onToggle: s.setHaptics,
      ),
    ]),
    MenuSection(title: S.premium, [
      MenuEntry(
        icon: Icons.workspace_premium_outlined,
        label: S.lifetimeName,
        onTap: () {
          Navigator.pop(context);
          showLifetimeSheet(context);
        },
      ),
      MenuEntry(
        icon: Icons.restore,
        label: S.restorePurchases,
        onTap: () {
          Navigator.pop(context);
          showLifetimeSheet(context);
          Future<void>.delayed(
            const Duration(milliseconds: 400),
            Premium.instance.restore,
          );
        },
      ),
    ]),
    MenuSection(title: S.yourCounter, [
      MenuEntry(
        icon: Icons.key_outlined,
        label: S.saveProgress,
        onTap: () => showRecoveryCode(context, s),
      ),
      MenuEntry(
        icon: Icons.login,
        label: S.haveCode,
        onTap: () => askRecoveryCode(context, s),
      ),
    ]),
    MenuSection(title: S.help, [
      MenuEntry(
        icon: Icons.help_outline,
        label: S.howItWorks,
        onTap: () => info(S.howItWorks, S.howItWorksBody),
      ),
    ]),
  ];
}

Future<void> showRecoveryCode(BuildContext context, RubbleStore s) {
  final code = s.recoveryCode();
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(S.saveProgress),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            S.recoveryBody,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.maybeOf(context)
              ?..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(S.copied)));
          },
          child: Text(S.copy),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.close),
        ),
      ],
    ),
  );
}

Future<void> askRecoveryCode(BuildContext context, RubbleStore s) async {
  final ctl = TextEditingController();
  String? error;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.haveCode),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 22,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: 'XXXX-XXXX-XXXX',
            labelText: S.enterCode,
            errorText: error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.cancel),
          ),
          TextButton(
            onPressed: () {
              if (s.applyRecoveryCode(ctl.text)) {
                Navigator.pop(context);
                ScaffoldMessenger.maybeOf(context)
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(S.codeApplied)));
              } else {
                setState(() => error = S.codeInvalid);
              }
            },
            child: Text(S.restoreCode),
          ),
        ],
      ),
    ),
  );
}
