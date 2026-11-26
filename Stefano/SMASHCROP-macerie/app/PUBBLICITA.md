# Pubblicità: Meta, TikTok, Google Ads, Apple Ads

Nella copia con le macerie gli SDK sono già montati con **valori segnaposto**.
Finché un codice è segnaposto, quella piattaforma resta spenta e l'app funziona normalmente.
Quando hai i codici veri, sostituiscili nei punti indicati qui sotto (o mandali a Claude).

## Stato

- **Meta: fatto** (26 nov 2026). App "SmashCrop PDF & Image" su Meta for Developers, ID app `4528815827358406`, token client già inseriti nei tre file. Non collegata a un portfolio business (si può fare da Impostazioni).
- Google (Firebase): da creare (Fulvio) e mandare i codici.
- TikTok: dopo la pubblicazione sugli store.
- Apple Ads: niente da fare.

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
- **Google**: console.firebase.google.com → crea progetto → aggiungi app Android (pacchetto `com.memeinitaly.smashcrop`) e iOS (bundle ID `com.memeinitaly.smashcrop`) → Impostazioni progetto: **ID progetto**, **Numero progetto (sender ID)**, e per ogni app **Chiave API** e **ID app**. Poi in Google Ads → Strumenti → Account collegati → **Firebase / Google Analytics** e importa gli eventi come conversioni.
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

1. **Testo della richiesta di tracciamento**: già fatto in 6 lingue (`ios/Runner/<lingua>.lproj/InfoPlist.strings`, insieme ai testi del permesso Foto).
2. **TikTok su iPhone (SKAdNetwork)**: già aggiunti in `Info.plist` gli ID di TikTok/Pangle (`238da6jt44`, `22mmun2rn5`). Quando si attiva TikTok, controllare in TikTok Ads Manager se ne chiede altri.
3. **Privacy negli store** (non è Xcode: è il questionario sui siti di Apple e Google al momento della pubblicazione):
   - App Store Connect → Privacy dell'app: dichiarare "Identificatori (ID dispositivo)" e "Dati d'uso (interazione con il prodotto)" usati per **pubblicità di terze parti / analisi**, collegati al tracciamento.
   - Google Play → Sicurezza dei dati: stessi dati (ID pubblicità, interazioni con l'app).
   - Il testo della privacy dentro l'app è già aggiornato (6 lingue).
4. **Europa (GDPR) su Android**: Android non ha una richiesta come l'ATT. Per gli utenti europei la cosa corretta è un banner di consenso prima di attivare Meta e TikTok (es. Google UMP). È il prossimo passo consigliato se le campagne girano in Europa.
5. **iCloud**: già nel progetto (`Runner.entitlements`); in Xcode basta controllare che in Signing & Capabilities compaia iCloud → Key-value storage.
6. L'iOS minimo è già 15.0 (richiesto da Meta e TikTok).

## Pubblicità dentro l'app (mediazione) — consigli per Fulvio

Oggi nell'app non c'è nessuna pubblicità: l'acquisto "SmashCrop a vita" promette "niente pubblicità",
quindi **i banner vanno messi prima di pubblicare** (altrimenti Apple può contestare la promessa).

**Rete:** AdMob con mediazione e bidding (`google_mobile_ads` in Flutter), con le reti in bidding più
forti: Meta Audience Network, AppLovin, Liftoff, Pangle, Unity. In Europa AdMob richiede il modulo di
consenso **Google UMP** (GDPR) prima di caricare annunci: è il banner di consenso che fa Fulvio.

**Dove e quando (in ordine di importanza):**
1. **Interstiziale dopo un salvataggio o una condivisione riuscita**: è la pausa naturale, il file è
   già al sicuro. Regole: mai al primo salvataggio, poi al massimo 1 ogni 3 salvataggi e mai due entro
   3 minuti. Mai prima di salvare, mai durante il taglio o l'animazione di SMASH.
2. **Banner adattivo in fondo alla home**, sotto "Carica immagini / Carica PDF", con spazio dai
   pulsanti (le regole di Google vietano annunci attaccati ai tasti, per i clic per sbaglio).
   **Nell'editor niente banner**: lo spazio serve all'immagine e alle linee A/B.
3. **Video con premio (facoltativo)**, solo se l'utente lo sceglie: per esempio "Guarda un video:
   macerie doppie per i prossimi 5 tagli" oppure "Prova Tycoon per 24 ore". Piace e rende bene.
4. **Annuncio all'apertura: sconsigliato** (irrita e fa disinstallare).

**Collegamenti con l'app:**
- con l'acquisto a vita **nessun annuncio**: controllare `Premium.instance.owned`
  (`lib/features/premium/premium.dart`) prima di caricare qualsiasi annuncio;
- sotto banner e interstiziale un piccolo "Togli la pubblicità per sempre" che apre
  `showLifetimeSheet(context)` (`lib/features/premium/lifetime_sheet.dart`);
- aggiungere gli **ID SKAdNetwork** delle reti in `ios/Runner/Info.plist`;
- aggiornare la **pagina privacy** (memeinitaly.store/pages/smashcrop-privacy, la modifica Stefano o
  Claude) e i questionari privacy di Apple e Google, perché gli annunci raccolgono dati;
- **app-ads.txt**: va messo nella radice del sito indicato negli store. Su Shopify non si possono
  caricare file nella radice: da valutare (sito sviluppatore diverso o reindirizzamento).
