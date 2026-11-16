# REGOLE MY11 – Come si creano i file .my11

Regole fisse da seguire per ogni file. Il riferimento approvato per le formazioni è **"CAG 1 - 0 FRO.my11"**.

---

## 1. Regole generali (valgono per tutti i file)

1. Il file **.my11 è un archivio ZIP** con `manifest.json` nella radice. Le immagini stanno in `images/` (cartelle immagini/loghi) o in `formations/N/` (formazioni).
2. **Base a filo dello slot.** La base del soggetto (busto, maglietta, stemma) deve toccare il bordo inferiore dell'immagine. Sotto non deve restare nessun margine trasparente, altrimenti ingrandendo l'immagine nell'app fluttua sopra lo slot.
3. **App leggera.** Le PNG si comprimono al massimo senza perdita visibile: PNG a palette, ottimizzato. Il peso non deve mai superare quello degli originali. Le immagini a tinta unita vanno compresse ancora di più.
4. **Sfondo trasparente** per facce, magliette e loghi.
5. **Etichette (label) in MAIUSCOLO.** Per i giocatori: il cognome, con iniziale puntata solo se serve a distinguere ("B. FERNANDES", "D. COSTA"). Per le squadre: il nome della squadra.
6. **Nomi.** Squadre straniere con il nome internazionale (inglese o lingua originale), squadre italiane in italiano.
7. **Doppioni.** Prima di aggiungere una squadra controllare che non ci sia già. Stessa squadra con un'altra edizione di gioco o un'altra stagione **non** è un doppione.
8. **Modifiche invasive** (sovrascrivere o cancellare contenuti esistenti): chiedere prima.

---

## 2. Cartelle immagini (facce / giocatori)

- **Formato:** `"format":"my11-pics-folder"`
  - **cartella singola:** `version 1`, solo `images`
  - **con sottocartelle:** `version 2`, `images` + `subfolders` e immagini in `images/sub_N/`
- **Ogni immagine:** `{"file":"images/img_N.png","libraryFileName":"slotimg_<id>_<N>.png","label":"COGNOME"}`
- **Prima immagine di ogni (sotto)cartella:** lo **stemma della squadra**, senza label.
- **Nome della sottocartella:**
  - squadre attuali: nome squadra + stagione, es. "Cagliari 26/27"
  - squadre dei videogiochi: nome squadra + gioco, es. "LAZIO FIFA99", "MILAN PES 5"
- **Facce:**
  - PNG trasparente, rapporto circa 15:16 (es. 350×373)
  - soggetto centrato, base a filo del bordo inferiore
  - circa 25–45 KB ciascuna
- **Ritaglio da screenshot:** solo il busto del giocatore, senza la targhetta del nome e senza pezzi dei vicini.
- **Omonimi nella stessa squadra:** distinguerli con l'iniziale, es. "NZOLA" e "G.NZOLA".

## 3. Cartelle loghi

- **Formato:** `"format":"my11-logos-folder"`, `version 2`, con le stesse chiavi delle cartelle immagini.
- **Ogni logo:** `{"file":"images/img_N.png","libraryFileName":"logo_<id>_<N>.png","label":"NOME SQUADRA"}`
- **Immagine:** PNG quadrato trasparente (400×400), logo centrato con la base a filo del fondo.
- **Ordine:** alfabetico nella (sotto)cartella. Per le cartelle per nazione: prima Europa, poi Sud America.
- **Loghi poco leggibili sullo sfondo scuro dell'app:** usare la versione chiara (es. Tottenham, Juventus, Athletico-PR).
- **Loghi già usati nell'app:** se si modifica il file, mantenere invariati i `libraryFileName`, così i loghi restano collegati.

---

## 4. File formazione

### 4.1 Struttura
```
manifest.json   {"format":"my11-formation-folder","version":1,"folderName":"<titolo cartella>","formations":[{"dir":"formations/0"}, ...]}
formations/N/manifest.json
formations/N/slots/*.png       (banner + facce)
formations/N/logos/left.png
formations/N/logos/right.png
formations/N/thumbnail.png
```
- **Ogni `formations/N/manifest.json` deve iniziare con `"format":"my11-formation","version":1`.** Senza, l'app dice che il file è impossibile da importare.
- **Una formazione:** si parte sempre dal **modello del modulo** (file Moduli). Si copia il suo manifest e si cambia solo quello che serve. Stile, stadio ("Filler (1)") e posizione degli slot restano quelli del modello.
- **Altri sport:** i modelli (tennis, basket e futuri) stanno in `Stefano/Moduli altri sport/`. Tennis: `Modulo_tennis.my11`, 1 vs 1, un giocatore in alto e uno in basso, campo da tennis del catalogo (`h68996830h`).
- **NBA / basket:** moduli di riferimento Base_nba (1-3-1) e Modulo_nba_2 (2-1-2), campo da basket del catalogo (`catalogStadiumId` g16040824g, immagine del campo inclusa nel file come fa l'app). Qui gli slot si possono spostare: PG e SG in basso, ali ai lati, centro sotto canestro. Titolo = nome squadra, logo squadra a sinistra e logo NBA a destra. Quintetto = i 5 con più partenze da titolare in stagione. Canotte nello stile MY11 con i colori reali della squadra.
- **Moduli disponibili:** 3-4-2-1, 3-4-3, 3-5-2, 4-2-3-1, 4-4-2, 4-3-3, 4-1-4-1, 5-4-1, 5-3-2, 4-4-1-1, 4-3-2-1, 4-3-1-2.
- **Non inventare moduli e non spostare gli slot.** Si usano solo i 12 moduli di riferimento, così come sono. Se il modulo reale non esiste (es. 3-5-1-1, 3-4-1-2, 4-2-2-2), si sceglie il più coerente tra quelli disponibili e lo si usa senza modifiche. Esempi: 3-5-1-1 → 3-5-2, 3-4-1-2 → 3-5-2, 4-2-2-2 → 4-4-2.

### 4.2 Titolo
| Tipo | Formato | Esempio |
|---|---|---|
| Pagella partita | CASA gol - gol TRASFERTA, sigle a 3 lettere | `CAG 1 - 0 FRO` |
| Formazione storica / videogioco | NOME SQUADRA + GIOCO | `LAZIO FIFA99` |
- **Sottotitolo:** vuoto. **Nome del file:** il titolo + `.my11`.
- **Sigle Serie A:**

| Squadra | Sigla | Squadra | Sigla | Squadra | Sigla | Squadra | Sigla |
|---|---|---|---|---|---|---|---|
| Milan | MIL | Inter | INT | Juventus | JUV | Napoli | NAP |
| Roma | ROM | Lazio | LAZ | Atalanta | ATA | Fiorentina | FIO |
| Bologna | BOL | Torino | TOR | Genoa | GEN | Cagliari | CAG |
| Como | COM | Lecce | LEC | Udinese | UDI | Parma | PAR |
| Sassuolo | SAS | Monza | MON | Venezia | VEN | Frosinone | FRO |

### 4.3 Loghi
- **Pagella:** logo della squadra di **casa a sinistra**, della **trasferta a destra**, sempre, anche se la pagella è della squadra in trasferta.
- **Formazione videogioco:** **stemma della squadra a sinistra**, **logo del videogioco a destra**.
- **Squadre senza stemma** (es. nazionali del Mondiale 98): bandiera. All Star: logo del torneo.

### 4.4 Giocatori e posizioni
- In campo i **11 titolari** nel modulo giusto, ognuno nella sua posizione: terzino sinistro a sinistra, ala destra a destra, ecc.
- **Regola degli slot:** gli slot del modello vanno ordinati dal portiere all'attacco e divisi in linee secondo il modulo (1 + cifre del modulo). In ogni linea vanno da sinistra a destra.
- **Formazioni da Fantacalcio.it:**
  - squadra di **casa**: ogni linea è elencata da **destra a sinistra**
  - squadra in **trasferta**: le linee vanno dall'attacco al portiere, ogni linea da **sinistra a destra**
- **Screenshot con il portiere in alto:** la squadra è vista al contrario, quindi si invertono i lati.
- **Facce:** dal file della squadra, confrontando il cognome senza accenti.
- **Faccia mancante:** si ritaglia dalle foto fornite. Se non c'è, nello slot va solo il nome (in futuro: la maglietta della squadra dalla cartella Maglie).
- **Nomi duplicati nella squadra:** iniziale del nome, es. "D. COSTA" e "A. COSTA".

### 4.5 Riserve
- La **casella riserva va SOLO negli slot dove c'è stato un cambio**: il subentrato va nella riserva del titolare che ha sostituito. Negli altri slot c'è solo il titolare.
- Nel manifest: `slotReserveIds` contiene solo gli slot con un sostituto, `showReserves: false`, e in `reserveNames` il valore `""` per tutti gli altri slot.
- **Più cambi sullo stesso slot:** si mette il primo subentrato (la riserva è una sola).
- **Formazioni videogioco:** nessuna riserva.

### 4.6 Voti ed eventi (pagelle)
- **Voti:** SOLO **Fantacalcio.it**, mai Diretta/Flashscore né fantacalcio-online.com. Per le competizioni che Fantacalcio.it non copre (es. nazionali): pagelle di un giornale sportivo.
- **Pagina voti di Fantacalcio.it:**
  - scaricarla con User-Agent da browser reale
  - il voto vero è nell'attributo `data-value`
  - scartare le righe civetta senza nome e l'allenatore
  - "-" = s.v., quindi nessun voto
- **Eventi** (anche multipli, con `count`):

| Evento | Valore nel file |
|---|---|
| Gol | `goal` |
| Assist | `assist` |
| Autogol | `ownGoal` |
| Rigore parato | `savedPenalty` |
| Gol subito | `concededGoal` |
| Rigore sbagliato | `missedPenalty` |
| Giallo | `yellowCard` |
| Rosso | `redCard` |
| Doppio giallo | `doubleYellow` |

- **Doppio giallo:** si segna solo `doubleYellow`, non anche giallo + rosso.
- **Si ignorano:** "Man of the match" e "Uscito per infortunio".
- Voto ed eventi del subentrato vanno nei campi della riserva (`slotReserveRatings`, `slotReserveLiveEvents`).

### 4.7 Dimensioni e testo
- **Grandezza immagini:** `globalPhotoScale` = **1,30** (barra immagini a 130). Cambia solo le facce.
- **Grandezza slot:** non toccare `globalSlotWidthScale` e `globalSlotHeightScale`, che restano quelli del modello.
- **Nome che sborda dal riquadro:** ridurre il testo **solo di quello slot** (`slotFontScales`) quanto basta per farlo rientrare, minimo 0,6. Esempi: VAN NISTELROOY, LICHTSTEINER.
- **Slot con riserva:** la riduzione vale per lo slot e tiene conto anche del nome della riserva. Esempio: MENDY con riserva KEVIN CARLOS → 0,75.

### 4.8 Banner, stadio, anteprima
- **Anteprima (thumbnail):** come sfondo si usa la base stadio di default (`Stadi/Base (1).jpg`; per il basket `Stadi/Basket.jpg`), con titolo e loghi nella barra nera in alto.
- **Ordine:** le formazioni di una cartella vanno in ordine alfabetico.
- **Slot che non si toccano:** nessuno slot (foto o etichetta) e nemmeno il banner deve toccare o sovrapporsi, neanche in parte, a un altro. Se succede si fanno micro-spostamenti (pinnedCenters), simmetrici, lasciando almeno lo spazio che c'è tra le righe della Roma di riferimento. Per il 3-4-2-1 si usano le posizioni della Roma.
- **Banner "CREATED WITH MY11":** sempre **in basso a sinistra**, identico al modello (stesso id, file, posizione e scala). Le altre immagini libere del modello si tolgono.
- **Stadio:** quello del modello, "Filler (1)".
- **Anteprima (thumbnail):** quella semplice a **campo verde** con titolo, loghi, facce e nomi. Serve a riconoscere i file generati automaticamente.
- **Dati di prova del modello** (MOREIRA, PROVA, "MIL 2 - 1 LAZ", voti ed eventi finti): vanno tutti tolti.
- **Id e date:** `id` nuovo `frm_<timestamp µs>`, con `createdAt`/`updatedAt` correnti.

---

## 5. Pagelle automatiche

- **Quando:** **175 minuti dopo il fischio d'inizio**. Se la partita non è finita, si ricontrolla **ogni 5 minuti**.
- **Appena finita:** si crea il file e si invia. I dati mancanti restano vuoti, ma il file parte comunque.
- **Invio:** una sola volta per partita e squadra.
- **Pagella:** solo per la squadra scelta (una delle squadre del file facce). L'avversaria può essere una qualunque. Se giocano due squadre scelte, si fanno due file.
- **Ambiente:** deve funzionare a computer spento, a costo zero se possibile (vedi note per Fulvio).

## 6. Controllo finale prima di consegnare

- **Formazione:** 11 titolari, modulo giusto, ognuno nella posizione giusta.
- **Riserve:** solo dove c'è un cambio, nello slot del giocatore sostituito.
- **Pagelle:** voti uguali a Fantacalcio.it, gol coerenti con il risultato.
- **Titolo e loghi:** titolo nel formato giusto, loghi a sinistra e a destra corretti.
- **Banner:** presente in basso a sinistra.
- **Immagini:** basi a filo dello slot, nessun nome che sborda, immagini a 1,30, slot invariati.
- **File:** `manifest.json` valido e ogni file citato presente nello ZIP. Peso il più basso possibile.
