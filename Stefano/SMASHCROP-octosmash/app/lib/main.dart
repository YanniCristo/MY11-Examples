import 'package:flutter/services.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdfrx/pdfrx.dart';

import 'app/app.dart';
import 'features/ads/ads_tracker.dart';
import 'features/notifications/notifications.dart';
import 'features/premium/premium.dart';
import 'features/rubble/application/rubble_store.dart';
import 'features/rubble/application/skin_assets.dart';
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
  // in sottofondo, dopo il primo disegno: la skin in uso e la prossima da
  // sbloccare sono pronte quando servono
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final store = RubbleStore.instance;
    SkinImages.preload(store.skin);
    final next = store.nextEvolution;
    if (next != null) SkinImages.preload(next);
    // pubblicità: richiesta di tracciamento (iPhone) e SDK, dopo la prima
    // schermata
    // dopo Firebase (serve alle push) partono le notifiche
    AdsTracker.instance.start().then((_) => Notifications.instance.start());
    // l'acquisto a vita: prezzo e acquisti in sospeso
    Premium.instance.start();
  });
}
