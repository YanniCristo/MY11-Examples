# Idea a parte: OctoSmash — Oscura e Imbianca

> Solo un'idea, separata da tutto: non fa parte né dell'app lite (SMASHCROP) né dell'app
> ufficiale con le macerie (SMASHCROP-macerie). Nessun codice, nessun file di quei progetti va
> toccato per questa idea finché Stefano non decide di partire.

## A cosa serve

Coprire con un rettangolo **nero** o **bianco** una zona di un'immagine o di un PDF (dati
personali su bollette, estratti conto, documenti da inviare). Solo coprire: niente modifica
del testo dei documenti.

## Come si attiva (aggiornato 26 nov 2026)

- **Tocco lungo su "Rimuovi porzione"** → si entra nella modalità OctoSmash, sullo stesso
  schema della regolazione fine al pixel.
- La riga dei tasti cambia:
  - **"Rimuovi porzione" diventa "✓ Fatto"** al centro;
  - **a sinistra**, al posto di Undo + Orizzontale, un unico tasto **⬜ Bianco**;
  - **a destra**, al posto di Verticale + Redo, un unico tasto **⬛ Nero**.
  - i due tasti sono un quadrato del loro colore con un **"+" del colore opposto** al centro
    (⬜ con + nero, ⬛ con + bianco): si capisce subito che da lì si **aggiungono** rettangoli.
- Toccando ⬜ o ⬛ un **rettangolo** di quel colore compare **al centro** dell'immagine.
- **I quattro angoli del rettangolo** (deciso il 26 nov 2026):
  - **due angoli opposti ridimensionano** (si tira l'angolo e il rettangolo si allarga o si
    stringe);
  - **un angolo sposta** il rettangolo; lo sposta anche trascinare il suo interno;
  - **un angolo ruota** il rettangolo a 360°.
  - Ogni angolo ha la sua icona (↘ ridimensiona, ✥ sposta, ⟳ ruota) per capire cosa fa.
- **Cosa si colora:** solo l'interno del rettangolo, cioè quello che si vede bianco o nero.
  Il **contorno** del rettangolo e le maniglie degli angoli servono solo a vederlo e a
  manovrarlo: **sotto di loro non si colora** (al contrario del taglio, dove le linee rosse
  sono comprese).
- **Aiuto per rimetterlo dritto:** mentre si ruota compaiono una **linea tratteggiata
  orizzontale e una verticale** che passano per il centro del rettangolo, come riferimento
  per riportarlo in bolla. Solo un aiuto visivo, **niente calamita** (il rettangolo non scatta
  da solo: Stefano odia le app con la calamita); al massimo una vibrazione leggera quando è
  esattamente dritto.
- **✓ Fatto** → l'OctoSmash giusto spruzza l'inchiostro e la zona diventa bianca o nera
  definitivamente. Si può annullare con Undo come un taglio.

## I personaggi

**Il nome base è OctoSmash** (sempre "OctoSmash + nome" per le varianti).

- **OctoSmash Bianco**, robot con 8 tentacoli, tutto bianco → spruzza **inchiostro nero**
  → tasto ⬛ Nero / *Oscura*.
- **OctoSmash Nero**, tutto nero → spruzza **inchiostro bianco** → tasto ⬜ Bianco / *Imbianca*.
- Stessa testa e stessi occhi di SMASH, con i tentacoli al posto di braccia e gambe, così si
  riconoscono come parte della famiglia. L'OctoSmash Nero sullo sfondo scuro dell'app va
  contornato (bordo chiaro o bagliore) per vedersi.

## Entrare e uscire dalla modalità OctoSmash

- **Entrare:** tocco lungo su "Rimuovi porzione", oppure dal **menu ☰**, sotto
  "Collezione": voce **"Passa a OctoSmash"** (in OctoSmash diventa **"Passa a SMASH"**).
  La voce c'è solo nell'editor con un file caricato (deciso il 26 nov 2026).
- **Interruttore on/off in OctoSmash** (cambiato il 26 nov 2026): mostra la testa di
  OctoSmash e, se lo si spegne, **OctoSmash si addormenta** come SMASH: l'inchiostro si
  posa subito senza animazione e senza litri. Non fa più uscire verso SMASH. Lo stato è
  separato da quello di SMASH e resta salvato.
- **Uscire:**
  - **tocco lungo su "✓ Fatto"**;
  - oppure dalla **riga delle pagine**: in modalità OctoSmash uno dei tasti grandi
    ("Pag. 1 di 1", "Aggiungi" o "Layout" nei PDF) diventa **"← Torna a SMASH"**.
    Le frecce ‹ › restano per cambiare pagina.
- **L'altro tasto grande della riga delle pagine** diventa il **tasto dell'angolo**
  (deciso il 26 nov 2026):  **[ ◀ ]  ⟳ 3°  [ ▶ ]**
  - ◀ ▶ ruotano il rettangolo selezionato di **1° alla volta**; tenendo premuto scorre
    (come le frecce della precisione al pixel);
  - al centro l'**angolo attuale**;
  - **toccando il numero** il rettangolo torna dritto a **0°** (il "Raddrizza").
  - Serve anche per i documenti fotografati storti: il rettangolo segue l'inclinazione.
  - Si accende solo con un rettangolo selezionato, come il cestino.

## Eliminare un rettangolo

- Si usa il **cestino** che c'è già nella riga delle pagine.
- Appena butti dentro un rettangolo, quello è **selezionato** (contorno e maniglie visibili)
  e il **cestino si illumina**: un tocco e il rettangolo sparisce.
- Con più rettangoli: si tocca quello da togliere per selezionarlo, poi il cestino.
- Senza nessun rettangolo selezionato il cestino resta spento.
- **Priorità sulla pagina:** il cestino oggi cancella anche le pagine (con più pagine è già
  acceso). Finché c'è almeno un rettangolo in lavorazione, **il rettangolo domina**: il
  cestino cancella solo il rettangolo selezionato, mai la pagina. Quando non ci sono più
  rettangoli in lavorazione (tutti tolti o confermati con "Fatto"), il cestino torna a
  cancellare la pagina come sempre.

## Garanzie

- L'app **non dichiara** che l'oscuramento sia a prova di recupero dei dati: si copre ciò
  che si vede, senza promesse di sicurezza (decisione di Stefano, 26 nov 2026). Quindi niente
  frasi tipo "dati protetti" o "redazione sicura" negli store e negli annunci.

## Contatore e Collezione

- Contatore dell'inchiostro **separato** da quello delle macerie (deciso il 26 nov 2026).
- Quando arriva OctoSmash **cambia tutto in alto**: la barra passa ai **litri di inchiostro**
  e l'interruttore on/off mostra l'OctoSmash al posto di SMASH. Uscendo dalla modalità
  tornano i kg di macerie e SMASH.
- **Un solo contatore per tutti gli inchiostri** (deciso il 26 nov 2026): nero, bianco e
  colorato (pipetta e tavolozza) si sommano negli stessi litri, con gli stessi contenitori.
- Stessa dinamica delle macerie: obiettivi da riempire e **evoluzioni** con le loro skin.
  Le linee di personaggi (Bianco, Nero, e i nuovi a colori) restano come skin da sbloccare,
  ma il contatore dei litri è unico.

## Collezione

- Nella schermata Collezione un tasto **🔄 cambia** passa dalla collezione di **SMASH** a
  quella di **OctoSmash** e viceversa (stessa schermata, stessa grafica: obiettivi, skin,
  evoluzioni, ognuna col suo contatore: kg di macerie o litri di inchiostro).
- Si apre sulla collezione della modalità in cui si è (da SMASH → SMASH, da OctoSmash → OctoSmash).
- **Il 🔄 cambia solo la vista, mai la modalità dell'app** (deciso il 26 nov 2026):
  - l'app si apre **sempre con SMASH**, anche se l'ultima volta si era in OctoSmash;
  - in OctoSmash si entra **solo** col tocco lungo su "Rimuovi porzione";
  - nella collezione OctoSmash si sceglie quale OctoSmash usare (come la skin di SMASH):
    la scelta vale per quando si entrerà in OctoSmash, ma non porta in quella modalità.

## Consigli ancora da valutare (Claude, 26 nov 2026)

- **Farla scoprire:** popup di novità una volta sola all'aggiornamento ("Tieni premuto
  Rimuovi porzione per coprire di bianco o nero") + paragrafo in "Come funziona".
- **Tocco lungo accidentale su Rimuovi porzione:** tempo più lungo (~0,8 s) e vibrazione netta.
- **Undo dopo "Fatto":** si annulla tornando a SMASH e usando Undo, oppure tocco lungo sul
  cestino in OctoSmash per annullare l'ultimo colpo d'inchiostro.
- **Più rettangoli prima di "Fatto":** sì, un solo "Fatto" e un solo spruzzo per tutti.
- **Acquisto a vita:** OctoSmash resta gratis; una skin speciale (es. OctoSmash Oro) solo
  con "a vita".

## Rettangoli colorati: pipetta e tavolozza (idea del 26 nov 2026)

- In OctoSmash la riga diventa: **[⬜+] [⬛+] [✓ Fatto] [💧 pipetta] [🎨 tavolozza]**
  (quattro tasti quadrati come Annulla/Orizzontale, Fatto al centro più stretto).
- **💧 Pipetta:** punti il dito sull'immagine o sul PDF, lasci andare, prende quel colore e
  mette il rettangolo di quel colore. Personaggio nuovo con l'ampolla che preleva il colore.
- **🎨 Tavolozza:** scelta tra tanti colori, fatta bene. Personaggio multicolore, iridescente.
- Inchiostro colorato: va nello stesso contatore unico dei litri.
- Da decidere: lente d'ingrandimento sopra il dito per la pipetta; se il tasto pipetta
  ricorda l'ultimo colore (tocco = usa, tocco lungo = nuovo prelievo); com'è fatta la
  tavolozza (griglia ~24 colori + colori presi + colore libero?); nomi e forma dei due
  personaggi (OctoSmash Pipetta / OctoSmash Prisma?); velo al 50% anche per i colorati.

## Da decidere

- Più rettangoli prima di "Fatto": il "+" lo suggerisce (ogni tocco ne aggiunge uno), da confermare.
- Quando uscire: non all'uscita dell'app, ma come primo aggiornamento lanciato come novità
  (notifica, post e annuncio dedicato alla privacy), per non togliere forza al taglio.
