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

## 2. Cartelle immagini (facce / giocatori / maglie)

### 2.1 Struttura del file
- **File base:** partire da `Stefano/Modelli di riferimento/Riferimento_cartella_immagini.my11` (manifest e immagini già corretti).
- **Formato:** `"format":"my11-pics-folder"`
  - **cartella singola:** `version 2`, `images` + `"subfolders":[]`
  - **con sottocartelle:** `version 2`, `images` + `subfolders` e immagini in `images/sub_N/`
- `folderName` = nome della cartella come la vuole Stefano (es. "PALERMO", "ATP TENNIS PLAYERS", "NBA").
- **Ogni immagine:** `{"file":"images/img_N.png","libraryFileName":"slotimg_<id>_<N>.png","label":"COGNOME"}`
- **Ordine:** quello indicato da Stefano (sinistra→destra, alto→basso nei collage); se non indicato, alfabetico.
- **Prima immagine:** lo **stemma/logo della squadra** quando richiesto (label = nome squadra, es. `PALERMO`).

### 2.2 Etichette (label)
- Solo **cognome in MAIUSCOLO**, con gli accenti giusti (es. `ESTÉVEZ`, `LEHEČKA`).
- Cognomi lunghi abbreviati come dice Stefano (es. `D.FOKINA`, `A.-ALIASSIME`).
- Omonimi nella stessa squadra: iniziale davanti (es. `NZOLA` / `G.NZOLA`).
- Sottocartelle: squadre attuali = nome + stagione ("Cagliari 26/27"); videogiochi = nome + gioco ("LAZIO FIFA99").

### 2.3 Ritaglio delle foto
- Le foto le fornisce Stefano (collage o singole); Claude **non scarica foto di persone dal web**.
- Dai collage: individuare ogni riquadro, prendere **solo quel giocatore** (niente pezzi dei vicini, niente targhette).
- **Mezzobusto:** testa, spalle e busto; sfondo trasparente (se non lo è, scontornare).
- Se le foto hanno difetti in basso (es. braccia mancanti), tagliare **subito sopra la fine della manica**, solo quando Stefano lo chiede.

### 2.4 Base a filo (obbligatorio)
1. L'**ultima riga di pixel** dell'immagine deve essere **piena** (soggetto opaco fino al bordo). Nessuna riga trasparente o sfumata sotto: se c'è, tagliarla.
2. **Proporzione minima 300×320** (larghezza × altezza). Se il soggetto è più largo che alto (es. 300×255), aggiungere **spazio trasparente in alto** fino a 300×320. Altrimenti l'app adatta l'immagine al riquadro, la centra in verticale e resta una striscia di campo tra maglia ed etichetta.
3. Soggetto centrato in orizzontale; larghezza tipica 300 px.

### 2.5 Peso
- PNG ottimizzati; foto vere circa 60–130 KB ciascuna, maglie/canotte a tinta unita a palette (pochi KB).
- Mai più pesanti degli originali.

### 2.6 Controllo prima di consegnare
- Anteprima a griglia con le etichette per verificare ordine e nomi.
- Per ogni immagine: ultima riga piena e altezza ≥ 320 per larghezza 300.
- Salvare su GitHub in `Copia file Fulvio (con possibili modifiche)/Pics/`; per il tennis anche i PNG singoli in `Pics/ATP Giocatori/`.

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
- **Altri sport:** i modelli (tennis, basket e futuri) stanno in `Stefano/Moduli altri sport/`. Tennis: regole complete in `REGOLE_TENNIS.md`; si parte da `Moduli altri sport/Riferimento_tennis.my11`.
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

- **Quando:** **115 minuti dopo il fischio d'inizio**. Se la partita non è finita, si ricontrolla **ogni 5 minuti**.
- **Appena finita:** si crea il file e si invia. I dati mancanti restano vuoti, ma il file parte comunque.
- **Invio:** una sola volta per partita e squadra.
- **Pagella:** solo per la squadra scelta (una delle squadre del file facce). L'avversaria può essere una qualunque. Se giocano due squadre scelte, si fanno due file.
- **Ambiente:** deve funzionare a computer spento, a costo zero se possibile (vedi note per Fulvio).
- **Fonte voti Serie A:** pagina `fantacalcio.it/voti-fantacalcio-serie-a/<stagione>/<giornata>`, primo voto della riga (Redazione Fantacalcio); "55" = senza voto. La pagina voti della singola partita mescola righe finte: non usarla.
- **Archivio su GitHub:** ogni file partita con pagelle va **sia inviato in chat sia caricato** in `Stefano/Pagelle partite/Giornata N/` (una sottocartella per giornata, es. `Giornata 12`). Nome del file uguale al titolo (es. `NAP 1 - 1 LAZ.my11`). Se le squadre scelte sono due nella stessa partita, i due file vanno nella stessa giornata.

## 6. Controllo finale prima di consegnare

- **Formazione:** 11 titolari, modulo giusto, ognuno nella posizione giusta.
- **Riserve:** solo dove c'è un cambio, nello slot del giocatore sostituito.
- **Pagelle:** voti uguali a Fantacalcio.it, gol coerenti con il risultato.
- **Titolo e loghi:** titolo nel formato giusto, loghi a sinistra e a destra corretti.
- **Banner:** presente in basso a sinistra.
- **Immagini:** basi a filo dello slot, nessun nome che sborda, immagini a 1,30, slot invariati.
- **File:** `manifest.json` valido e ogni file citato presente nello ZIP. Peso il più basso possibile.

- **Controllo base (obbligatorio):** prima di consegnare, verificare che l'ultima riga di pixel di ogni immagine sia piena (soggetto opaco fino al bordo inferiore, nessuna riga trasparente o sfumata sotto). Se ci sono righe trasparenti in fondo, tagliarle. Inoltre l'immagine deve avere proporzione almeno **300×320** (alta quanto o più del riquadro dello slot): se il soggetto è più largo che alto, aggiungere spazio trasparente **in alto** fino a 300×320, altrimenti l'app lo centra e si stacca dal fondo.

- **Prima di usare maglie o chiedere foto:** cercare sempre i volti già pronti su GitHub (`Pics/Serie A.my11` con le sottocartelle squadra "Como 26/27", "Inter 26/27"…, `Pics/PALERMO.my11`, `Pics/ATP Giocatori/`). Le maglie si usano solo se i volti non ci sono.
