import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../features/home/home_screen.dart';
import '../features/settings/preferences.dart';
import 'strings.dart';
import 'theme.dart';

class SmashCropApp extends StatelessWidget {
  const SmashCropApp({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    // cambiando lingua tutta l'app si ridisegna con i nuovi testi
    return ValueListenableBuilder<AppLang>(
      valueListenable: S.current,
      builder: (context, lang, _) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        // la chiave legata alla lingua ricostruisce tutta l'app (anche la
        // schermata già aperta) con i testi nuovi
        child: MaterialApp(
          key: ValueKey(lang),
          title: S.appName,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          home: HomeScreen(preferences: preferences),
        ),
      ),
    );
  }
}
