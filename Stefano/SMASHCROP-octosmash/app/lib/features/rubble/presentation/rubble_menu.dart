import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/links.dart';
import '../../../app/strings.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_menu.dart';
import '../application/rubble_store.dart';
import '../../premium/lifetime_sheet.dart';
import '../../premium/premium.dart';
import 'collection_screen.dart';

/// Le voci del menu ☰ della versione con le macerie, prima di lingua e
/// "Condividi l'app".
List<MenuSection> rubbleMenuSections(
  BuildContext context,
  RubbleStore s, {
  MenuEntry? modeSwitch,
}) {
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
      // nell'editor: passa a OctoSmash / passa a SMASH
      ?modeSwitch,
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
      if (!kIsWeb)
        MenuEntry(
          icon: Icons.notifications_none,
          label: S.notifications,
          toggle: s.notify,
          onToggle: s.setNotify,
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
      MenuEntry(
        icon: Icons.mail_outline,
        label: S.writeUs,
        onTap: () => launchUrl(
          Uri(
            scheme: 'mailto',
            path: kSupportEmail,
            query: 'subject=SmashCrop',
          ),
        ),
      ),
      if (!kIsWeb)
        MenuEntry(
          icon: Icons.star_outline,
          label: S.rateApp,
          onTap: () async {
            final r = InAppReview.instance;
            // Android: scheda del Play Store; iPhone: pagina per scrivere la
            // recensione, o la richiesta di sistema finché manca l'ID
            if (defaultTargetPlatform == TargetPlatform.android ||
                kAppStoreId.isNotEmpty) {
              await r.openStoreListing(appStoreId: kAppStoreId);
            } else if (await r.isAvailable()) {
              await r.requestReview();
            }
          },
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
  final focus = FocusNode();
  String? error;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.haveCode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.enterCode,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            // campo a riquadro, con margine interno e testo al centro: il
            // cursore non sta attaccato al bordo ed è facile tenerci premuto
            TextField(
              controller: ctl,
              autofocus: true,
              focusNode: focus,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 20,
                letterSpacing: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX-XXXX',
                errorText: error,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.red, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // incollare a mano in un campo vuoto è scomodo: un tocco e basta
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.content_paste, size: 20),
              label: Text(S.paste, style: const TextStyle(fontSize: 16)),
              onPressed: () async {
                String text = '';
                try {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  text = data?.text?.trim() ?? '';
                } catch (_) {}
                if (text.isEmpty) {
                  // il browser non ci fa leggere gli appunti (succede nelle
                  // pagine aperte dentro altre app): si incolla a mano
                  focus.requestFocus();
                  return;
                }
                ctl.text = text;
                ctl.selection = TextSelection.collapsed(offset: text.length);
                setState(() => error = null);
              },
            ),
          ],
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
