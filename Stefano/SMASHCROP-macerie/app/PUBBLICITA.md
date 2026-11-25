# Pubblicità: Meta, TikTok, Google Ads, Apple Ads

Nella copia con le macerie gli SDK sono già montati con **valori segnaposto**.
Finché un codice è segnaposto, quella piattaforma resta spenta e l'app funziona normalmente.
Quando hai i codici veri, sostituiscili nei punti indicati qui sotto (o mandali a Claude).

## Dove vanno i codici

| Piattaforma | File | Cosa sostituire |
|---|---|---|
| Meta | `app/lib/features/ads/ads_config.dart` | `metaAppId` |
| Meta | `app/android/app/src/main/res/values/strings.xml` | `facebook_app_id`, `facebook_client_token` |
| Meta | `app/ios/Runner/Info.plist` | `FacebookAppID`, `FacebookClientToken` |
| TikTok | `app/lib/features/ads/ads_config.dart` | `tiktokAndroidId`, `tiktokIosId`, `tiktokIosAppId` (+ `tiktokAndroidAppId` se il pacchetto Android cambia) |
| Google (Firebase) | `app/lib/features/ads/ads_config.dart` | `firebaseProjectId`, `firebaseSenderId`, chiave e App ID di Android e iOS |
| Apple Ads | — | niente: usa AdServices di Apple |

Non servono i file `google-services.json` / `GoogleService-Info.plist`: i valori di Firebase si mettono nel codice.

## Dove trovarli

- **Meta**: developers.facebook.com → Le mie app → crea app (tipo "Altro" → "Business") → Impostazioni → Di base: **ID app**; Impostazioni → Avanzate → Sicurezza: **Token client**. Poi in Events Manager collega l'app.
- **TikTok**: TikTok Ads Manager → Strumenti → Events → App → aggiungi l'app (Android e iOS separati): **TikTok App ID** per ciascuna. Serve anche l'**ID dell'app sull'App Store** (il numero nell'URL dell'App Store).
- **Google**: console.firebase.google.com → crea progetto → aggiungi app Android (pacchetto `com.stefanofancello.smashcrop`) e iOS (bundle ID dell'app) → Impostazioni progetto: **ID progetto**, **Numero progetto (sender ID)**, e per ogni app **Chiave API** e **ID app**. Poi in Google Ads → Strumenti → Account collegati → **Firebase / Google Analytics** e importa gli eventi come conversioni.
- **Apple Ads**: nessun codice. Le installazioni sono misurate da Apple; in più l'app chiede ad Apple se arriva da una campagna e lo segna in Firebase (`apple_ads_install`).

## Cosa fa l'app

- **iPhone**: al primo avvio, dopo la prima schermata, chiede il **permesso di tracciamento** (ATT). Se l'utente dice no, Meta e TikTok ricevono solo dati senza identificativo.
- **Eventi** mandati a Firebase, Meta e TikTok (una volta sola per telefono):
  - `first_cut`: primo taglio fatto
  - `first_save`: primo file salvato o condiviso
  - `first_evolution`: prima evoluzione di SMASH
  - acquisto a vita: `purchase` con prezzo e valuta (da collegare quando c'è l'acquisto vero: `AdsTracker.instance.lifetimePurchase(...)`)
- Nel browser (webapp) non parte niente.
- I file dell'utente non escono mai dal telefono: si mandano solo i nomi degli eventi.

Nelle campagne conviene ottimizzare su `first_save` (utenti che l'app l'hanno usata davvero), poi sull'acquisto quando ci sarà.

## Da fare prima di pubblicare

1. **Testo della richiesta di tracciamento**: ora è in inglese in `Info.plist` (`NSUserTrackingUsageDescription`). Per averlo in 6 lingue va aggiunto in Xcode un file `InfoPlist.strings` localizzato.
2. **TikTok su iPhone (SKAdNetwork)**: in `Info.plist` ci sono gli ID di Google e Meta; aggiungere la lista di TikTok presa dalla loro documentazione.
3. **Privacy negli store**:
   - App Store Connect → Privacy dell'app: dichiarare "Identificatori (ID dispositivo)" e "Dati d'uso (interazione con il prodotto)" usati per **pubblicità di terze parti / analisi**, collegati al tracciamento.
   - Google Play → Sicurezza dei dati: stessi dati (ID pubblicità, interazioni con l'app).
   - Il testo della privacy dentro l'app è già aggiornato (6 lingue).
4. **Europa (GDPR) su Android**: Android non ha una richiesta come l'ATT. Per gli utenti europei la cosa corretta è un banner di consenso prima di attivare Meta e TikTok (es. Google UMP). È il prossimo passo consigliato se le campagne girano in Europa.
5. **iCloud** (promemoria): in Xcode, Signing & Capabilities → iCloud → Key-value storage.
6. In Xcode l'iOS minimo resta 15.0 (richiesto da Meta e TikTok).
