import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';
import 'features/rubble/application/rubble_store.dart';
import 'features/settings/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await AppPreferences.load();
  prefs.applyLanguage();
  RubbleStore.instance = await RubbleStore.load();
  runApp(SmashCropApp(preferences: prefs));
}
