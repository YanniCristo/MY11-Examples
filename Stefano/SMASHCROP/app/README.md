# SmashCrop: app Flutter

Editor per immagini e PDF (milestone 1–7 del Master Prompt). Manca la milestone 8: rifiniture e prove su iPhone e Android veri.

## Come avviarla

```bash
flutter pub get
flutter test          # 49 test: motore di taglio, cronologia, geometria, SMASH, editor, impaginazione PDF
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
- **PDF** di qualsiasi formato, anche con pagine di misure diverse. Il navigatore "Pag. 2 di 4" e il pulsante **Layout PDF** stanno in una sola riga compatta.
- **Pagine renderizzate solo quando servono**, fino a 200 DPI con il lato lungo entro 2600 px. In memoria restano al massimo 4 pagine.
- **Impaginazione.** Al primo taglio di ogni pagina si apre il pannello con le **4 impaginazioni** (Centrato, In alto, Riduci pagina, Personalizza posizione), con anteprima dal vivo. "In alto" è il suggerimento iniziale; poi diventa l'ultima scelta fatta.
- **Personalizza posizione**: si trascina il blocco intero dentro il foglio, senza ridimensionarlo, e si chiude con **Conferma posizione** o **Annulla**.
- **Ogni pagina è indipendente**: tagli, impaginazione, posizione, Undo/Redo. "Applica a tutte le pagine modificate" chiede conferma.
- **PDF finale**: stesse pagine, stesso ordine. Le pagine non tagliate sono copiate intatte, testo selezionabile compreso. Quelle tagliate diventano un'immagine (JPEG qualità 92) nel foglio scelto. Le misure in punti sono esatte, e prima di confermare il file viene riaperto per controllarlo.
- **Salvataggio del PDF** con il selettore di sistema (File su iPhone, Documenti su Android) oppure **Condividi**.

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
    pdf_processing/         impaginazione (PageFrame), apertura/resa/esportazione PDF (pdfrx), pannello Layout
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

- **Pagine PDF tagliate.** Diventano immagini: niente testo selezionabile, link o firme valide su quelle pagine. Il pannello Layout lo dice all'utente.
- **PDF protetti da password.** Non si aprono: l'app mostra un messaggio e non prova ad aggirare la protezione.
- **JPEG.** Una foto JPEG/HEIC salvata viene ricompressa (qualità 95): i pixel restano quelli dell'originale, ma la compressione JPEG ne altera leggermente i valori. Le sorgenti PNG restano identiche.
- **Immagini enormi.** Oltre 8192 px per lato il risultato a schermo si disegna a blocchi invece che come immagine unica (funziona, ma è un po' più lento). Oltre 16.000 px l'immagine viene rifiutata.
- **Pressione prolungata sulle maniglie** per farle scorrere lungo la linea: rimandata. Con le maniglie fuori dall'immagine non serve; la si può aggiungere se servirà.
- **Mai provata su un telefono vero.** Controllata con i test e con una build web in Chrome: è stato provato un PDF di 4 pagine di misure diverse, con Centrato, Riduci pagina e Personalizza posizione, e il file salvato è stato verificato.
