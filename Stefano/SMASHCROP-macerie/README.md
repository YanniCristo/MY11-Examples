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

## Ancora da fare

- Acquisto a vita (Tycoon + niente pubblicità) e "Ripristina acquisti".

Codice: `lib/features/rubble/` (contatore, skin, effetti, Collezione, menu).
Immagini e suoni: `assets/rubble/`, `assets/sounds/` (mp3).
