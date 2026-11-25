import 'package:flutter/services.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';
import 'features/rubble/application/rubble_store.dart';
import 'features/settings/preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();
  // Android: "Carica immagini" apre subito la galleria di sistema
  // (selettore foto), non la scelta tra app e gestore file
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) picker.useAndroidPhotoPicker = true;
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await AppPreferences.load();
  prefs.applyLanguage();
  RubbleStore.instance = await RubbleStore.load();
  runApp(SmashCropApp(preferences: prefs));
}
