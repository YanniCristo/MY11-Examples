# SmashCrop: app Flutter

Prima versione funzionante dell'editor per le immagini (milestone 1–4 e 7 del Master Prompt). Il PDF arriva nelle milestone 5–6.

## Come avviarla

```bash
flutter pub get
flutter test          # 35 test: motore di taglio, cronologia, geometria, SMASH, editor
flutter run           # su iPhone/Android collegato o simulatore
```

Versione di riferimento: Flutter 3.50.1 stable (Dart 3.14). Da questa versione Material è il pacchetto separato `material_ui`: nel codice si importa `package:material_ui/material_ui.dart` al posto di `package:flutter/material.dart`.

Prima della pubblicazione:
- **Bundle ID** provvisorio: `com.stefanofancello.smashcrop`. Va sostituito con quello definitivo in Xcode (iOS) e in `android/app/build.gradle.kts`.
- **Icone dell'app** già generate dall'icona 3D (`branding_src/app_icon_1024.png`). Per rigenerarle: `dart run flutter_launcher_icons`.

## Cosa fa

- **Home** con il prima/dopo e SMASH. Load Image apre la libreria foto.
- **Editor** con il layout delle interfacce approvate: Condividi e Salva in alto; Undo, Redo e zoom sotto; il documento al centro; Rimuovi porzione, Orizzontale, Verticale, SMASH, Load Image e Load PDF in basso.
- **Linee A/B indipendenti** con maniglie *fuori* dall'immagine: a sinistra e a destra in orizzontale, sopra e sotto in verticale.
- **Orizzontale e Verticale** fanno anche da interruttori: premendo quello attivo la selezione si nasconde, ripremendolo torna.
- **Taglio reale**, orizzontale e verticale. Le parti si ricongiungono e la nuova selezione compare **0,8 s dopo il ricongiungimento**, con o senza SMASH.
- **SMASH**: i 18 frame HD, con il pugno sull'epicentro della fascia. Entra da sinistra, esce a destra e resta sempre dentro il viewport. La scelta acceso/spento viene ricordata.
- **Zoom** da 1x a 5x con lo slider o con due dita; spostamento con un dito quando l'immagine è ingrandita. Le linee restano agganciate al contenuto.
- **Undo e Redo** su tutta la cronologia. L'originale non viene mai toccato.
- **Salva** nelle Foto e **Condividi** con il foglio di sistema, a piena risoluzione: PNG se la sorgente è PNG/WebP/GIF, altrimenti JPEG qualità 95.

## Come è fatta

```
lib/
  app/                      tema, testi (strings.dart, pronti per la traduzione), MaterialApp
  core/widgets/             marchio SMASHCROP, pulsanti, freccia doppia
  features/
    home/                   schermata iniziale
    editor/
      domain/               modello del taglio, cronologia, viewport, selezione (Dart puro, testato)
      application/          EditorController: stato, taglio, animazione, timer
      presentation/         schermata, viewport con gesti e maniglie, painter, toggle SMASH
    image_processing/       motore pixel (RasterImage) e importazione immagini
    animation/              frame e tempi di SMASH, posizione del pugno
    export/                 file finale, Salva nelle Foto, Condividi
    settings/               preferenze locali
assets/smash/               smash_01..18.webp, tela comune 730×470, pugno in (485, 215)
test/                       test unitari e del controller
```

**Come funziona il taglio.** Un taglio a fascia intera elimina solo righe (orizzontale) o solo colonne (verticale). Qualunque sequenza di tagli equivale quindi a dire quali righe e quali colonne dell'originale restano (`StripDocument`).
- A schermo il risultato si ricompone copiando i blocchi 1:1 dall'originale.
- Il file finale si costruisce nello stesso modo con `RasterImage.compose`, in un isolate.
- Undo e Redo riapplicano la lista dei tagli all'originale, senza tenere in memoria una copia dei pixel per ogni passaggio.
- I test verificano su sequenze casuali che il risultato coincida pixel per pixel con i tagli applicati uno alla volta.

**Animazione e risultato sono separati.** Il controller calcola subito il documento finale. `CutTimeline` decide solo cosa mostrare in ogni istante: la fascia che si rompe, le parti che si avvicinano, il frame di SMASH. Il documento cambia quando il ricongiungimento è completo, e da quel momento parte il conteggio della nuova selezione.

## Limiti noti di questa versione

- **PDF** non ancora implementato: Load PDF mostra un avviso.
- **JPEG.** Una foto JPEG/HEIC salvata viene ricompressa (qualità 95): i pixel restano quelli dell'originale, ma la compressione JPEG ne altera leggermente i valori. Le sorgenti PNG restano identiche.
- **Immagini enormi.** Oltre 8192 px per lato il risultato a schermo si disegna a blocchi invece che come immagine unica (funziona, ma è un po' più lento). Oltre 16.000 px l'immagine viene rifiutata.
- **Pressione prolungata sulle maniglie** per farle scorrere lungo la linea: rimandata. Con le maniglie fuori dall'immagine non serve; la si può aggiungere se servirà.
- **Mai provata su un telefono vero.** Controllata con i test e con una build web in Chrome.
