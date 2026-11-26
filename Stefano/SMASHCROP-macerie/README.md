# SmashCrop — versione con le macerie (copia di lavoro)

Copia separata dell'app SmashCrop con l'idea "SMASH mangia-macerie".
**L'app principale è in `../SMASHCROP/app` e non viene toccata da questa versione.**

Specifica completa: [`../SMASHCROP/docs/idea-macerie.md`](../SMASHCROP/docs/idea-macerie.md).

## Cosa c'è in più rispetto all'app principale

- **Contatore delle macerie** (kg, blocco 5 cm, 1,5 kg/L) in alto a sinistra nell'editor e nella home:
  totale, testa dello SMASH in uso, barra verso la prossima evoluzione, testa della prossima.
- **A ogni colpo**: gli elementi della skin esplodono dalla fascia, la maggior parte cade e sparisce
  sotto i pulsanti, 4 pezzi si fermano, si illuminano e volano a curva nel contatore ("gnam", "+kg").
- **6 personaggi**: SMASH, Burp (150 kg), Popcorn (450 kg), Muahaha (1.500 kg), Mamma Mia (4.500 kg),
  Tycoon (acquisto a vita, non ancora collegato). Tappa del secchio a 15 kg.
- **Evoluzione** a tutto schermo e **Collezione** animata (sagome per i bloccati, card da condividere).
- **Suoni** (4 varianti a caso per personaggio, seguono il silenzioso dell'iPhone) e **vibrazione**.
- **Menu ☰**: Collezione, suoni, vibrazione, Premium (in arrivo), codice di recupero, aiuto.
- **Codice di recupero** (12 caratteri con firma) per cambio telefono / webapp.
- **Effetti per skin** sopra la base comune (vetro + elementi): SMASH onda d'urto, polvere e
  tremolio; Burp bolla di gomma + gas verde con bollicine; Popcorn chicchi che scoppiano; Muahaha
  fumo viola, pipistrelli, fantasmini, scintille; Mamma Mia pomodoro da cartone che si schiaccia +
  basilico e spaghetti; Tycoon monete d'oro e coriandoli. Disegnati in codice
  (`lib/features/rubble/presentation/skin_effects.dart`), più grandi con tagli più grandi, spenti
  con "riduci movimento", visibili anche nella Collezione.
- **Salvataggio automatico senza login**: iCloud (chiave-valore) su iPhone e Google Block Store su
  Android. Unione delle copie: chili più alti e tutto ciò che è sbloccato da entrambe.

## Pubblicità

SDK di Meta, TikTok, Google (Firebase) e Apple Ads già montati con valori segnaposto, richiesta di tracciamento su iPhone ed eventi: vedi **PUBBLICITA.md**.

## Xcode: niente da fare a mano

iCloud (Key-value storage) è già nel progetto (`ios/Runner/Runner.entitlements`). Aprendo il progetto
con la firma automatica, in Signing & Capabilities deve comparire **iCloud** con **Key-value storage**
spuntato: basta controllare che ci sia.

Prova: fai qualche taglio con SMASH, aspetta qualche secondo, cancella l'app, reinstallala
(TestFlight) con lo stesso ID Apple: i kg devono tornare.
Su Android: stessa prova con un telefono con backup Google attivo.

## Acquisto "SmashCrop a vita"

Già nel codice (`lib/features/premium/`, pacchetto `in_app_purchase`): niente pubblicità + SMASH Tycoon,
pagato una volta, con "Ripristina acquisti". Dove compare:
- bottoncino arancione **"👑 A vita"** in alto nella home (sparisce dopo l'acquisto);
- Collezione: toccando Tycoon col lucchetto, o il pulsante "Sblocca con SmashCrop a vita";
- menu ☰ → Premium (SmashCrop a vita · Ripristina acquisti);
- **una sola volta**, poco dopo il primo file salvato o condiviso (solo nelle app, non nel web).
Dopo l'acquisto Tycoon si indossa subito e parte l'evento "Purchase" per le campagne.
Nel web il pulsante spiega che si compra dall'app.

**Da fare negli store** (stesso ID su entrambi): `smashcrop_lifetime`
- App Store Connect → l'app → Acquisti in-app → **Non consumabile**, ID `smashcrop_lifetime`, prezzo, nome e descrizione.
- Google Play Console → Monetizza → Prodotti → **Prodotti in-app**, ID `smashcrop_lifetime`, prezzo.
Il prezzo mostrato in app arriva dallo store, nella valuta di chi compra.
Prova: TestFlight con un account Sandbox (iPhone) e "tester delle licenze" (Android).

## Notifiche

Codice: `lib/features/notifications/notifications.dart`. Interruttore nel menu ☰ → SMASH → Notifiche.
Il permesso si chiede **una volta**, dopo il primo file salvato (dopo l'invito "SmashCrop a vita").

**Locali (già funzionanti, senza server):** tre promemoria alle 18:30 dopo 2, 6 e 14 giorni senza
aprire l'app ("SMASH ha fame 🍽️ Ti mancano X kg per sbloccare…", "Un pugno e via 👊",
"SMASH si annoia… 😴"), in 6 lingue. Ogni volta che l'app va in secondo piano ripartono da capo:
chi usa l'app non li vede mai.

**Push (pronte, si accendono con i codici Firebase):** Firebase Cloud Messaging. Ogni telefono è
iscritto agli argomenti `tutti` e `lang_it` / `lang_en` / `lang_fr` / `lang_es` / `lang_pt` / `lang_de`:
dalla console Firebase → Messaging → nuova campagna → "Argomento" si manda a tutti o per lingua.
Cosa serve:
1. codici Firebase in `lib/features/ads/ads_config.dart` (da Fulvio);
2. **chiave APNs: fatta** (26 nov 2026). Nome "Push Notifiche", **Key ID `78298U6JVH`**,
   **Team ID `RFG6LF7869`**, ambienti Sandbox e Production, valida per tutte le app del team
   (anche MY11). Il file `AuthKey_78298U6JVH.p8` è stato scaricato **una volta sola** nei Download
   del PC di Stefano: va conservato al sicuro (Apple non lo fa riscaricare) e **non** va messo su git;
3. Firebase → Impostazioni progetto → Cloud Messaging → app iOS → carica il file .p8 con
   Key ID `78298U6JVH` e Team ID `RFG6LF7869`.

Già nel progetto: permessi e ricevitori Android, icona bianca `ic_stat_smash`, compileSdk 37,
`aps-environment` in `Runner.entitlements` (Xcode attiva "Push Notifications" da solo con la
firma automatica), modalità in background "remote-notification".
Nota: l'App ID `com.stefanofancello.smashcrop` sul sito Apple non esiste ancora: lo crea Xcode
alla prima firma (o si cambia l'ID provvisorio prima).

## Ancora da fare

- I banner pubblicitari della versione gratis (con, sotto, "Togli la pubblicità per sempre").

Codice: `lib/features/rubble/` (contatore, skin, effetti, Collezione, menu).
Immagini e suoni: `assets/rubble/`, `assets/sounds/` (mp3).
