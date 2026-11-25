/// Codici delle piattaforme pubblicitarie.
///
/// SONO SEGNAPOSTO: finché un valore comincia con `METTI_` (o è tutto zeri)
/// quella piattaforma resta spenta e l'app funziona normalmente.
/// Dove trovarli e dove metterli: PUBBLICITA.md nella cartella dell'app.
/// Meta va messo anche nei file nativi (strings.xml su Android, Info.plist su
/// iPhone).
abstract final class AdsConfig {
  // --- Meta (Instagram / Facebook) ------------------------------------------
  static const metaAppId = '4528815827358406';

  // --- TikTok ----------------------------------------------------------------
  /// App ID dell'app sul Play Store (es. com.stefanofancello.smashcrop).
  static const tiktokAndroidAppId = 'com.stefanofancello.smashcrop';

  /// TikTok App ID per Android (Events Manager di TikTok Ads).
  static const tiktokAndroidId = 'METTI_TIKTOK_APP_ID_ANDROID';

  /// ID numerico dell'app sull'App Store (es. 6740000000).
  static const tiktokIosAppId = 'METTI_APPLE_APP_ID';

  /// TikTok App ID per iPhone (Events Manager di TikTok Ads).
  static const tiktokIosId = 'METTI_TIKTOK_APP_ID_IOS';

  // --- Google (Firebase Analytics → Google Ads) -----------------------------
  // Dalla console Firebase, Impostazioni progetto → Le tue app.
  static const firebaseProjectId = 'METTI_FIREBASE_PROJECT_ID';
  static const firebaseSenderId = 'METTI_FIREBASE_SENDER_ID';
  static const firebaseAndroidApiKey = 'METTI_FIREBASE_API_KEY_ANDROID';
  static const firebaseAndroidAppId = 'METTI_FIREBASE_APP_ID_ANDROID';
  static const firebaseIosApiKey = 'METTI_FIREBASE_API_KEY_IOS';
  static const firebaseIosAppId = 'METTI_FIREBASE_APP_ID_IOS';

  /// Valore vero (non segnaposto)?
  static bool isSet(String v) =>
      v.isNotEmpty &&
      !v.startsWith('METTI_') &&
      v.replaceAll('0', '').isNotEmpty;

  static bool get meta => isSet(metaAppId);
  static bool get tiktok =>
      isSet(tiktokAndroidId) && isSet(tiktokIosId) && isSet(tiktokIosAppId);
  static bool get firebase =>
      isSet(firebaseProjectId) &&
      isSet(firebaseSenderId) &&
      isSet(firebaseAndroidAppId) &&
      isSet(firebaseIosAppId);
}
