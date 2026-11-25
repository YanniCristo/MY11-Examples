import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/links.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../features/settings/preferences.dart';
import 'flag.dart';

/// Una voce del menu ☰. Con [toggle] diversa da `null` è un interruttore.
class MenuEntry {
  const MenuEntry({
    required this.icon,
    required this.label,
    this.trailing,
    this.toggle,
    this.onTap,
    this.onToggle,
  });

  final IconData icon;
  final String label;

  /// Testo a destra (es. la lingua scelta).
  final String? trailing;
  final bool? toggle;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
}

class MenuSection {
  const MenuSection(this.entries, {this.title});
  final String? title;
  final List<MenuEntry> entries;
}

/// Pulsante ☰ disegnato (non dipende dal font delle icone).
class MenuButton extends StatelessWidget {
  const MenuButton({super.key, required this.onTap, this.size = 40});

  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.menu,
      child: Material(
        color: AppColors.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _BurgerPainter()),
          ),
        ),
      ),
    );
  }
}

class _BurgerPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.text
      ..strokeWidth = s.width * .07
      ..strokeCap = StrokeCap.round;
    final x0 = s.width * .3, x1 = s.width * .7;
    for (final f in const [.36, .5, .64]) {
      c.drawLine(Offset(x0, s.height * f), Offset(x1, s.height * f), p);
    }
  }

  @override
  bool shouldRepaint(_BurgerPainter old) => false;
}

/// Apre il menu dal basso. [sections] sono le voci in più della pagina (per
/// esempio quelle di SMASH); lingua, "Condividi l'app", privacy e versione
/// ci sono sempre.
Future<void> showAppMenu(
  BuildContext context, {
  required AppPreferences preferences,
  List<MenuSection> sections = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) =>
        _MenuSheet(preferences: preferences, sections: sections),
  );
}

class _MenuSheet extends StatefulWidget {
  const _MenuSheet({required this.preferences, required this.sections});
  final AppPreferences preferences;
  final List<MenuSection> sections;

  @override
  State<_MenuSheet> createState() => _MenuSheetState();
}

class _MenuSheetState extends State<_MenuSheet> {
  Future<void> _language() async {
    final picked = await showModalBottomSheet<(AppLang?,)>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _LanguageSheet(preferences: widget.preferences),
    );
    if (picked == null) return;
    await widget.preferences.setLanguage(picked.$1);
    if (mounted) Navigator.of(context).pop();
    // cambiare lingua ricostruisce l'app: lo si fa a menu chiuso
    widget.preferences.applyLanguage();
  }

  Future<void> _shareApp() async {
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: S.shareAppText(kAppShareUrl),
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {}
  }

  void _privacy() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.privacy),
        content: SingleChildScrollView(
          child: Text(
            S.privacyBody,
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

  @override
  Widget build(BuildContext context) {
    final lang = widget.preferences.language;
    final sections = [
      ...widget.sections,
      MenuSection([
        MenuEntry(
          icon: Icons.translate,
          label: S.languageTitle,
          trailing: lang == null ? S.languageAuto : lang.nativeName,
          onTap: _language,
        ),
      ]),
      MenuSection([
        MenuEntry(icon: Icons.ios_share, label: S.shareApp, onTap: _shareApp),
      ]),
    ];
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              for (final s in sections) ...[
                if (s.title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                    child: Text(
                      s.title!.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                _Group(entries: s.entries, onChanged: () => setState(() {})),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _privacy,
                    child: Text(
                      S.privacy,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Text('·', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 12),
                  Text(
                    '${S.version} $kAppVersion',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.entries, required this.onChanged});
  final List<MenuEntry> entries;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.button,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 52, color: AppColors.border),
            _Row(entry: entries[i], onChanged: onChanged),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.entry, required this.onChanged});
  final MenuEntry entry;
  final VoidCallback onChanged;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  late bool? _on = widget.entry.toggle;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final on = _on;
    void tap() {
      if (on != null) {
        setState(() => _on = !on);
        e.onToggle?.call(!on);
        widget.onChanged();
      } else {
        e.onTap?.call();
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: e.onTap == null && on == null ? null : tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: SizedBox(
          height: 46,
          child: Row(
            children: [
              Icon(e.icon, size: 22, color: AppColors.text),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  e.label,
                  style: const TextStyle(color: AppColors.text, fontSize: 16),
                ),
              ),
              if (e.trailing != null)
                Text(
                  e.trailing!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              if (on != null)
                Switch(
                  value: on,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.red,
                  onChanged: (_) => tap(),
                )
              else if (e.onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Elenco delle lingue con le bandiere.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.preferences});
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final device = AppLang.device();
    Widget row(AppLang flag, String title, AppLang? value, {String? sub}) {
      final selected = preferences.language == value;
      return InkWell(
        onTap: () => Navigator.pop(context, (value,)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              LangFlag(flag),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub,
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
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                S.languageTitle,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            row(
              device,
              S.languageAuto,
              null,
              sub: '${S.languageDevice} · ${device.nativeName}',
            ),
            const Divider(height: 1, color: AppColors.border),
            for (final l in AppLang.values) row(l, l.nativeName, l),
          ],
        ),
      ),
    );
  }
}

/// Spunta rossa disegnata (non dipende dal font delle icone).
class CheckMark extends StatelessWidget {
  const CheckMark({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 20,
    height: 20,
    child: CustomPaint(painter: _CheckPainter()),
  );
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    c.drawPath(
      Path()
        ..moveTo(s.width * .18, s.height * .52)
        ..lineTo(s.width * .42, s.height * .74)
        ..lineTo(s.width * .84, s.height * .28),
      Paint()
        ..color = AppColors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .13
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => false;
}
