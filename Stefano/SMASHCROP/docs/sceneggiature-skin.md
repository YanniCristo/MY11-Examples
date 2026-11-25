# Sceneggiature delle skin di SMASH (18 immagini ciascuna)

Da dare a ChatGPT insieme alle **18 immagini originali di SMASH** (`assets/frames_hd/` o
`app/assets/smash/`), che fanno da riferimento per stile, dimensioni e posizioni.
Fa parte dell'idea [SMASH mangia-macerie](idea-macerie.md): da usare solo sulla copia dell'app.

---

## Istruzioni comuni (incollare sempre prima di ogni skin)

> Ti allego le 18 immagini del robot SMASH. Devi creare **18 nuove immagini dello stesso robot**
> per una nuova skin, seguendo la sceneggiatura qui sotto. Regole obbligatorie:
>
> 1. **Stesso personaggio, stesso stile 3D lucido, stesse proporzioni** dello SMASH originale: cambiano
>    solo colori, accessori, espressione e azione descritti.
> 2. **Ogni immagine: 730×470 pixel, PNG con sfondo trasparente.** Niente sfondo, niente pavimento,
>    niente ombra a terra estesa, niente bordi.
> 3. **Il robot guarda e agisce verso destra**, come nell'originale.
> 4. **Stessa scala in tutte le immagini:** sommità della testa a circa y = 75 px, piedi a circa
>    y = 350 px (come l'originale), salvo dove la sceneggiatura dice che si piega o salta.
> 5. **Immagine 1:** il robot sta entrando da sinistra, si vede solo in parte; nulla del robot oltre
>    x = 115 px. **Immagine 18:** sta uscendo a destra; nulla del robot prima di x = 566 px.
> 6. **Immagine 6 = momento del colpo.** Il punto d'impatto (dove arriva il colpo, il raggio, l'onda,
>    la pizza…) è **esattamente a x = 485 px, y = 215 px**, come il pugno dello SMASH originale.
> 7. **Non disegnare il foglio o la porzione da distruggere:** la disegna l'app. Disegna solo il
>    robot e i suoi effetti (raggi, onde, nuvolette, scritte da fumetto) diretti verso il punto
>    d'impatto.
> 8. **Immagini 15 e 16** sono la posa finale che resta a schermo più a lungo: devono essere
>    quasi uguali tra loro (piccola variazione per dare vita).
> 9. Stile per tutte le età: niente sangue, ferite, nudità, armi realistiche, niente testi oltre a
>    quelli indicati (scritte da fumetto in lettere grandi).
> 10. Nomina i file `skin_01.png` … `skin_18.png` nell'ordine.

**Struttura (uguale per tutte le skin, come SMASH):**

| Immagini | Fase |
|---|---|
| 1–3 | entrata da sinistra |
| 4–5 | carica del colpo |
| **6** | **colpo** (punto d'impatto 485, 215) |
| 7–9 | effetto del colpo che continua |
| 10–14 | ritorno in posizione, reazione buffa |
| 15–16 | posa finale (dura di più) |
| 17–18 | uscita di corsa verso destra |

---

## 1. SMASH Burp — *Riempi una carriola*

**Aspetto:** verde lime e verde oliva lucido al posto del rosso; **pancione rotondo** che sporge
dall'armatura (come se fosse pieno di macerie); occhi soddisfatti; piccolo tubo di scarico sulla
schiena.

| # | Scena |
|---|---|
| 1 | entra da sinistra camminando a gambe larghe, si vede metà robot e il pancione |
| 2 | avanza dondolando, mano sul pancione |
| 3 | si ferma, pancione in primo piano, guance che si gonfiano |
| 4 | inspira: torace e pancione si gonfiano, occhi stretti |
| 5 | massimo gonfiaggio, testa all'indietro, bocca chiusa che trema |
| **6** | **RUTTO:** bocca spalancata verso destra; **anello d'urto** verde trasparente che parte dalla bocca e arriva al punto d'impatto (485, 215); scritta fumetto **"BURP!"** grande |
| 7 | secondo anello più grande e più trasparente (eco), scritta "burp!" più piccola dietro la prima |
| 8 | terzo anello ancora più largo (eco), scritta "burp…" piccolissima; il robot ancora a bocca aperta |
| 9 | anelli che svaniscono, piccole bollicine verdi nell'aria |
| 10 | si sgonfia: pancione che torna normale, espressione sollevata |
| 11 | si batte il pancione con la mano, soddisfatto |
| 12 | piccolo "hic!" (singhiozzo) con bollicina verde sopra la testa |
| 13 | si copre la bocca con la mano, finto imbarazzato |
| 14 | posizione eretta, sorriso con gli occhi |
| 15 | pollice alzato, l'altra mano sul pancione |
| 16 | uguale alla 15, leggero rimbalzo del pancione |
| 17 | parte di corsa verso destra, pancione che ballonzola, nuvoletta di polvere dietro |
| 18 | esce a destra, si vede solo metà robot, scia di bollicine verdi |

**Effetto sulla porzione (lo fa l'app):** sbriciolamento a onde dal centro.

---

## 2. SMASH Popcorn — *Riempi una betoniera*

**Aspetto:** armatura **gialla burro** con **strisce verticali rosse e bianche** sul torace (come il
secchiello dei popcorn); palmi delle mani con griglie che si arroventano; occhi affamati.

| # | Scena |
|---|---|
| 1 | entra da sinistra a passo svelto, si vede metà robot |
| 2 | avanza sfregandosi le mani |
| 3 | si ferma, mani avanti, palmi verso destra |
| 4 | i palmi si arroventano di arancione, onde di calore tremolanti |
| 5 | calore al massimo, palmi bianco-arancio, occhi concentrati |
| **6** | **RAGGIO DI CALORE:** un raggio arancione ondulato parte dai palmi e arriva al punto d'impatto (485, 215); scritta fumetto **"POP!"** |
| 7 | primi popcorn che saltano in aria vicino al punto d'impatto, scritte "pop! pop!" piccole |
| 8 | pioggia di popcorn che vola verso il robot |
| 9 | il robot apre la bocca enorme verso l'alto, i popcorn ci cadono dentro |
| 10 | mastica a guance piene, popcorn che spuntano dalla bocca |
| 11 | ingoia, occhi chiusi di piacere |
| 12 | si pulisce la bocca con il dorso della mano |
| 13 | un ultimo popcorn gli cade in testa e rimbalza |
| 14 | lo afferra al volo e lo mangia |
| 15 | pollice alzato, guance ancora un po' piene |
| 16 | uguale alla 15, un popcorn che salta sulla sua spalla |
| 17 | parte di corsa verso destra, popcorn che cadono dietro |
| 18 | esce a destra, si vede solo metà robot, scia di popcorn |

**Effetto sulla porzione (lo fa l'app):** scoppio in popcorn che volano verso il robot.

---

## 3. SMASH Muahaha — *Riempi un cassone*

**Aspetto:** armatura **nero lucido e viola scuro**; **visore orizzontale rosso** al posto degli occhi
(una fessura luminosa unica); piccole punte sulle spalle; mantello corto viola strappato. Horror da
cartone animato, non spaventoso.

| # | Scena |
|---|---|
| 1 | entra da sinistra lentamente, avvolto da un filo di nebbia viola, si vede metà robot |
| 2 | avanza a passi lenti, mantello che svolazza |
| 3 | si ferma, testa bassa, il visore è spento |
| 4 | dietro di lui **sorge una luna rossa** grande e tonda; il visore si accende di rosso |
| 5 | alza la testa, il visore brilla intensamente, piccoli fulmini viola intorno |
| **6** | **RAGGIO LASER:** dal visore parte un raggio rosso sottile e dritto che arriva al punto d'impatto (485, 215), dove si apre un **portale circolare viola** |
| 7 | dal portale escono i primi **pipistrelli da cartone** (neri con occhi rossi tondi) |
| 8 | sciame di pipistrelli che vola verso il punto d'impatto, il robot ride a testa alta; scritta **"MUAHAHA!"** |
| 9 | pipistrelli che sciamano in cerchio, scritta "muahaha…" più piccola (eco) |
| 10 | il portale si richiude, ultimi pipistrelli che rientrano |
| 11 | la luna rossa tramonta dietro il robot, il visore torna fioco |
| 12 | si sistema il mantello con un gesto teatrale |
| 13 | un pipistrello gli si posa sulla spalla |
| 14 | lo accarezza con un dito |
| 15 | pollice alzato, visore che fa un "occhiolino" (lampeggio) |
| 16 | uguale alla 15, il pipistrello sulla spalla che sbatte le ali |
| 17 | parte di corsa verso destra, mantello al vento, scia di nebbia viola |
| 18 | esce a destra, si vede solo metà robot, il pipistrello che lo segue |

**Effetto sulla porzione (lo fa l'app):** mangiata a morsi, pezzo dopo pezzo.

---

## 4. SMASH Mamma Mia — *Riempi un camioncino*

**Aspetto:** armatura **bianca e rossa** con dettagli **verdi**; **cappello da cuoco** alto; grandi
**baffi** neri a manubrio; fazzoletto rosso al collo; mani con guanti bianchi.

| # | Scena |
|---|---|
| 1 | entra da sinistra tenendo in alto una pizza su una mano, si vede metà robot |
| 2 | avanza fischiettando, pizza in equilibrio sulle dita |
| 3 | si ferma, guarda verso destra, fa il gesto delle dita a "borsa" (mano a carciofo) |
| 4 | fa girare la pizza sul dito come un pallone da basket, scie di movimento |
| 5 | carica il lancio di lato come un frisbee, pizza che gira velocissima |
| **6** | **LANCIO:** la **pizza rotante** vola e arriva al punto d'impatto (485, 215) di taglio come una lama, scie circolari; scritta fumetto **"MAMMA MIA!"** |
| 7 | **schizzi di pomodoro da cartone** (rosso-arancio vivo, semini, foglie di basilico, pezzetti di mozzarella) che si allargano dal punto d'impatto |
| 8 | la pizza continua a girare oltre il punto d'impatto, altri schizzi |
| 9 | la pizza torna indietro come un boomerang verso il robot |
| 10 | la riprende al volo con una mano |
| 11 | ne stacca una fetta e la morde, filo di mozzarella |
| 12 | si bacia la punta delle dita: gesto dello chef (scintilla vicino alle dita) |
| 13 | si arriccia i baffi, soddisfatto |
| 14 | un ultimo schizzo di pomodoro gli finisce sul naso, si pulisce con il fazzoletto |
| 15 | pollice alzato, pizza nell'altra mano |
| 16 | uguale alla 15, baffi che si muovono in un sorriso |
| 17 | parte di corsa verso destra con la pizza sottobraccio |
| 18 | esce a destra, si vede solo metà robot, cappello da cuoco che sobbalza |

**Effetto sulla porzione (lo fa l'app):** affettatura + schizzi di pomodoro che colano e svaniscono.
Il pomodoro deve sembrare **sempre pomodoro da cartone**, mai sangue.

---

## 5. SMASH Tycoon — *a vita*

**Aspetto:** armatura **arancione lucida** con dettagli **dorati**; postura sicura e un po'
impettita. **Nessun altro riferimento a persone reali:** niente capelli, ciuffo, cravatta, scritte o
slogan. È solo un robot arancione che balla.

| # | Scena |
|---|---|
| 1 | entra da sinistra a passetti, si vede metà robot, braccia già piegate |
| 2 | **balletto:** pugni chiusi davanti al petto, avambraccio destro avanti e sinistro indietro, fianchi a destra |
| 3 | **balletto:** avambracci invertiti (sinistro avanti), fianchi a sinistra, passetto laterale |
| 4 | **balletto:** di nuovo destro avanti, testa che dondola soddisfatta |
| 5 | **si gira e si piega**: dà la schiena verso destra, sedere (armatura) puntato verso il punto d'impatto, sguardo malizioso da sopra la spalla |
| **6** | **SCORREGGIA:** **nuvoletta verde-gialla da cartone** che esce da dietro e un'**onda d'urto ad anelli** che arriva al punto d'impatto (485, 215); scritta fumetto **"PRRRT!"** |
| 7 | l'onda d'urto si allarga, polvere che vola via verso destra |
| 8 | anelli più larghi e trasparenti, la nuvoletta si dissolve |
| 9 | si raddrizza, si gira di nuovo verso destra |
| 10 | si sventola davanti al naso con la mano, faccia innocente |
| 11 | riprende il balletto: avambraccio destro avanti |
| 12 | balletto: avambraccio sinistro avanti, fianchi che ondeggiano |
| 13 | balletto: tutti e due i pugni che pompano all'altezza del petto |
| 14 | si ferma impettito, mento in alto |
| 15 | pollice alzato con un sorrisetto soddisfatto |
| 16 | uguale alla 15, piccolo dondolio dei fianchi |
| 17 | parte di corsa verso destra a passetti di danza |
| 18 | esce a destra, si vede solo metà robot, ultimo sbuffo di nuvoletta verde dietro |

**Effetto sulla porzione (lo fa l'app):** disintegrazione a soffio (polvere spazzata via).
**Niente musica** del brano associato al balletto.

---

## Dopo aver ricevuto le immagini

- Controllare che **robot e scala** siano coerenti con lo SMASH originale (testa ~75, piedi ~350).
- Controllare il **punto d'impatto** dell'immagine 6 (485, 215): se è spostato si corregge.
- Rifinitura come per SMASH: ordinamento, allineamento dei piedi, ridimensionamenti.
- Ogni skin avrà la sua **testa** (per interruttore, contatore e Collezione) ricavata dall'immagine 15.
