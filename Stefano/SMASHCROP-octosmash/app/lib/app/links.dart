/// Link e dati dell'app usati nel menu.
///
/// Quando l'app sarà sugli store, [kAppShareUrl] va sostituito con il link
/// dello store (o con una pagina che manda allo store giusto).
const String kAppShareUrl = 'https://claude.ai/artifact/T1yDWbBwuQ2wtKNESgvTn6';

/// Da tenere uguale a `version` in pubspec.yaml.
const String kAppVersion = '1.0.0';

/// Mail per l'assistenza ("Scrivici" nel menu e scheda degli store).
const String kSupportEmail = 'info@memeinitaly.store';

/// ID numerico dell'app sull'App Store (si legge in App Store Connect dopo
/// aver creato l'app). Finché è vuoto, "Valuta SmashCrop" su iPhone mostra
/// la richiesta di recensione di sistema.
const String kAppStoreId = '';

/// Pagine pubbliche (sul sito MEMEinITALY, raggiungibili solo col link):
/// da mettere nelle schede di App Store Connect e Google Play.
const String kPrivacyUrl = 'https://memeinitaly.store/pages/smashcrop-privacy';
const String kSupportUrl = 'https://memeinitaly.store/pages/smashcrop-supporto';
