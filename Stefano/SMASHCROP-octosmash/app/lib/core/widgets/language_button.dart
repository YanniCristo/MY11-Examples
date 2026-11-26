import 'package:material_ui/material_ui.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../features/settings/preferences.dart';
import 'app_menu.dart';
import 'flag.dart';

/// Bandiera, sigla e freccetta: al tocco apre il menu a tendina delle lingue.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, required this.preferences});

  final AppPreferences preferences;

  Future<void> _choose((AppLang?,) v) async {
    await preferences.setLanguage(v.$1);
    preferences.applyLanguage();
  }

  PopupMenuItem<(AppLang?,)> _item(
    AppLang flag,
    String title,
    AppLang? value, {
    String? subtitle,
  }) {
    final selected = preferences.language == value;
    return PopupMenuItem<(AppLang?,)>(
      value: (value,),
      height: subtitle == null ? 48 : 58,
      child: Row(
        children: [
          LangFlag(flag),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (selected) const CheckMark(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final device = AppLang.device();
    return PopupMenuButton<(AppLang?,)>(
      tooltip: S.languageTitle,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: AppColors.surface,
      elevation: 12,
      constraints: const BoxConstraints(minWidth: 230, maxWidth: 280),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      onSelected: _choose,
      itemBuilder: (context) => [
        _item(
          device,
          S.languageAuto,
          null,
          subtitle: '${S.languageDevice} · ${device.nativeName}',
        ),
        const PopupMenuDivider(height: 8, color: AppColors.border),
        for (final l in AppLang.values) _item(l, l.nativeName, l),
      ],
      child: Semantics(
        button: true,
        label: S.languageTitle,
        child: Container(
          height: 38,
          padding: const EdgeInsets.only(left: 10, right: 8),
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LangFlag(S.lang, width: 22),
              const SizedBox(width: 7),
              Text(
                S.lang.name.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const ChevronDown(size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
