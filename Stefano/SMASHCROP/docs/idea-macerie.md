# Idea: SMASH mangia-macerie

> **Stato:** solo idea, in definizione. **Non toccare l'app attuale.**
> Quando si decide di costruirla, si fa una **copia separata** dell'app
> (es. `Stefano/SMASHCROP-macerie/`) e si lavora solo lì.

Ultimo aggiornamento: 25 novembre 2026

---

## 1. Concetto

Ogni volta che SMASH dà il pugno, la porzione tolta diventa **macerie** che SMASH
si "mangia". Le macerie si accumulano in un contatore; a certe soglie SMASH
**evolve** e cambia aspetto.

- La funzione principale dell'app non cambia.
- SMASH diventa un personaggio "vivo", non solo un logo: fa tornare le persone.
- Due modalità chiare: **SMASH acceso** = c'è il gioco; **SMASH spento** = si lavora pulito e veloce.

## 2. Misura delle macerie

- Si misura l'**area tolta**, convertita in misura fisica:
  - PDF: misure vere della pagina (1 pt = 0,35 mm);
  - immagini: stima a 96 dpi.
- Un taglio è una superficie: per avere un volume si dà uno **spessore fisso al blocco** di macerie (5 cm).
- **Unità decisa: il PESO, in chili, sempre la stessa dall'inizio alla fine** (niente cambi g → kg → t:
  confondono). Densità delle macerie da cantiere: **1,5 t/m³** (1 litro = 1,5 kg).
  - si parte con i decimali: `0,30 kg` → `1,25 kg` → `12,4 kg` → `150 kg`;
  - fino a 999 kg al massimo 3 cifre; solo gli ultimi livelli arrivano a 4 (`1.500 kg`, `4.500 kg`).
- SMASH le macerie le **mangia**: "ha mangiato 12 kg" si capisce subito.
- Graficamente le macerie sono **cubetti** che cadono nel contatore.

### Spessore e soglie

**Indicazione (25 nov):** le soglie con blocco 10 cm sono **troppo basse**. Con il primo SMASH
bisogna lavorare di più: l'utente deve **affezionarsi**, usare l'app più a lungo ed essere
**bramoso** di arrivare alla prima evoluzione.

**Deciso (25 nov):** blocco **5 cm** (fascia tipica di un A4 ≈ 0,75 kg; A4 intero ≈ 4,5 kg).

| Soglia | Cosa succede | Tagli circa |
|---|---|---|
| 15 kg | tappa: "Hai riempito un secchio!" (nessuna evoluzione) | ~20 |
| 150 kg | **1ª evoluzione** – una carriola | ~200 |
| 450 kg | **2ª evoluzione** – una betoniera | ~600 |
| 1.500 kg | **3ª evoluzione** – un cassone | ~2.000 |
| 4.500 kg | **4ª evoluzione** – un camioncino pieno | ~6.000 |

(Equivalenti in volume: 10 L, 100 L, 300 L, 1 m³, 3 m³.)

Crescita più dolce (circa ×3 tra un livello e l'altro, non ×10): la prima evoluzione costa
lavoro, l'ultima è raggiungibile da chi usa l'app spesso.
Ritmo indicativo: con ~50 tagli a settimana la 1ª evoluzione arriva in circa 1 mese e l'ultima
in circa 2 anni; con ~10 a settimana la 1ª in circa 5 mesi.

Le tappe intermedie senza evoluzione (secchio, poi eventualmente altre) servono a dare piccole
soddisfazioni mentre si aspetta la prima evoluzione, senza regalarla.

Opzioni scartate: blocco 1 cm (troppo lento), blocco 10 cm con soglie da 1 L (troppo veloce).

## 3. Livelli ed evoluzioni

- A ogni soglia: "Hai riempito una carriola!" con l'**oggetto da cantiere** disegnato accanto a SMASH.
- SMASH cambia aspetto (armatura, colori, mascelle più grandi…) con una **breve animazione di evoluzione**.
- Da quel momento il pugno lo dà il nuovo SMASH.
- Da fare: **nomi e aspetto** di ogni forma di SMASH per livello.

## 3b. Collezione delle skin

**Cambio automatico:** quando SMASH evolve, la nuova skin si **indossa da sola** (fa parte della
festa dell'evoluzione). Chi preferisce la precedente la riprende dalla collezione in un tocco.

**Sezione "Collezione"** (le skin di SMASH):
- griglia con **tutte** le skin, nell'ordine delle evoluzioni (+ eventuali skin extra);
- **sbloccate:** si toccano per indossarle; quella in uso ha la spunta;
- **ancora da sbloccare:** visibili nel loro colore ma con un **lucchetto**, l'obiettivo e quanto
  manca (es. "Riempi una carriola · mancano 30 kg"), così fanno venire voglia;
- **gli oggetti da cantiere non sono i nomi delle skin**: sono l'obiettivo per sbloccarle
  ("Riempi una carriola"). Le skin hanno nomi propri di SMASH (da decidere);
- **skin extra** dell'acquisto a vita: **"SMASH Tycoon", arancione, con il balletto** (deciso 25 nov).
  Il nome è neutro, la parodia sta tutta nel movimento: chi capisce ride, lo store vede un robot
  che balla. Per chi non ha comprato resta chiusa con il prezzo.
  - il balletto è un'animazione propria (fotogrammi da disegnare), breve e saltabile: per esempio
    quando si indossa la skin o come festa dopo un pugno;
  - **niente musica** del brano associato (protetta): al massimo un suono originale;
  - nessun altro riferimento alla persona (niente nome, ciuffo, cravatta, slogan).
  (Scartata: "SMASH Trump" — nome + colore + balletto insieme sarebbero troppo espliciti.)
- anteprima: toccando una skin si vede SMASH che dà il pugno con quella skin.

**Dopo un'evoluzione:**
- **Prima evoluzione:** barra completa → "SMASH si è evoluto!" (circa 2 secondi) → si apre **da sola**
  la **Collezione**, con la nuova skin già indossata e l'etichetta **"Nuova"**: serve a far
  scoprire che la Collezione esiste. Si chiude con la **X** o con **"Continua a tagliare"**.
- **Dalla seconda in poi:** festa breve, poi avviso **"Nuova skin!"** con il tasto **"Vedi"** e il
  pallino rosso sul contatore; la Collezione la apre l'utente se vuole (non si interrompe il lavoro).
- **Mai nel mezzo di qualcosa:** se l'evoluzione arriva mentre è aperto il pannello del layout PDF,
  il posizionamento o un salvataggio, la festa aspetta che l'utente abbia finito.

**Dove si apre:**
- dalla **home**, toccando livello/barra di SMASH vicino al logo;
- dall'**editor**, toccando il contatore **quando SMASH è acceso** (da spento il tocco mostra
  "Attiva SMASH", come deciso).

**Come si capisce che si può toccare:**
- nel contatore, accanto alla testa dell'evoluzione, una piccola **freccetta ›** (come nelle liste
  del telefono: "qui c'è altro");
- un **pallino rosso** sul contatore quando c'è una skin nuova non ancora vista (sparisce aprendo la
  Collezione);
- **dopo il primo taglio con SMASH** (non al primo avvio), una volta sola: il contatore pulsa e
  compare la nuvoletta "Tocca per la tua collezione" per 3 secondi;
- in home, accanto a livello e barra, la stessa freccetta e la scritta "Collezione".

**Cosa cambia con la skin scelta:** l'animazione del pugno, la testa nell'interruttore e nel
contatore, la card da condividere. Il progresso verso la prossima evoluzione **non cambia**: nel
contatore a sinistra c'è la testa della skin **in uso**, a destra quella della **prossima
evoluzione** da sbloccare.

**Extra possibile (solo iPhone e Android che lo supportano):** cambiare anche l'icona dell'app con
quella della skin. Da valutare.

**Salvataggio:** la skin scelta e quelle sbloccate si salvano insieme al contatore (stessi
salvataggi senza account).

## 3c. Come sono fatte le skin (metodo)

Ogni skin = **una cartella con 18 immagini PNG** (sfondo trasparente, stessa struttura e stessi
tempi di SMASH: entrata, colpo, uscita) **+ una piccola scheda** (fotogramma del colpo, effetto
sulla porzione, eventuale suono).

- **Il personaggio** e i **suoi effetti** (laser, anelli del rutto, scritte da fumetto, braci…) si
  disegnano nelle 18 immagini.
- **La porzione** è il documento vero dell'utente (sempre diverso): la anima **l'app**, con pochi
  effetti riutilizzabili:

| Effetto sulla porzione | Descrizione |
|---|---|
| Frantumazione | schegge che volano (quello di oggi) |
| Sbriciolamento a onde | si sgretola dal centro verso fuori |
| Catapulta | viene sparata via fuori dallo schermo |
| Combustione | si annerisce e diventa cenere che sale |
| Schiacciamento | appiattita con crepe e tremore |
| Salto a ritmo | rimbalza a tempo e sparisce |

Aggiungere una skin in futuro = 18 immagini + una scheda, senza riscrivere l'app.
Le sceneggiature delle 18 immagini di ogni skin si scrivono quando nomi e comportamenti sono
confermati (da far realizzare con ChatGPT).

## 3d. I personaggi

| Obiettivo | Skin | Come distrugge | Effetto porzione | Stato |
|---|---|---|---|---|
| inizio | **SMASH** | pugno | frantumazione | esistente |
| Riempi una carriola | **SMASH Burp** | rutto dall'eco distruttivo | sbriciolamento a onde | confermata |
| Riempi una betoniera | SMASH Boing | molle ai piedi: salta sulla porzione e la catapulta via | catapulta | proposta |
| Riempi un cassone | SMASH Inferno *(o Phantom / Zombot)* | horror: visore laser rosso, luci che calano | combustione | proposta |
| Riempi un camioncino | SMASH Mamma Mia | gigante: entra facendo tremare tutto e ci si siede sopra | schiacciamento | proposta |
| a vita | **SMASH Tycoon** (arancione) | balletto | salto a ritmo | confermata |

Regole horror (Inferno): niente sangue, ferite, corpi o mostri realistici, niente jump scare né
urla; stile "Halloween per tutti" (buio, occhi che brillano, laser, braci, glitch), così l'app
resta per tutte le età.

## 4. Animazioni (leggere, mai bloccanti)

- Dopo ogni taglio: cubetti che volano/cadono nel contatore, "+0,75 kg", cifre che girano come un **contachilometri**.
- "Gnam" **proporzionato**: rapido per tagli piccoli, masticata più lunga per tagli grandi.
- **Mai** bloccare il lavoro o il salvataggio: chi taglia 50 pagine non deve aspettare.
- Animazione lunga solo per le **evoluzioni**.

## 5. SMASH spento: solo linguaggio visivo (niente testo fisso)

- Contatore **in grigio** con piccola icona di pausa ⏸, oppure **SMASH addormentato 💤** al posto dell'icona attiva: si capisce senza parole.
- Il messaggio compare **solo al tocco**: toccando il contatore grigio esce un tooltip di **2 secondi** "Attiva SMASH" e sparisce.
- Al massimo un **avviso una tantum**: la prima volta che si spegne SMASH, toast breve "SMASH dorme: niente macerie", poi mai più.
- **Niente conteggi retroattivi**: i tagli fatti con SMASH spento non contano ("le macerie le mangia lui").
- SMASH **acceso di default** al primo avvio; se l'utente lo spegne, l'app ricorda la scelta.
- Interruttore a portata di mano (la testa di SMASH nell'editor, come oggi), non nascosto nelle impostazioni.

## 6. Il contatore

**Editor:** piccolo contatore in un angolo del riquadro, compatto:

```
 12,4 kg [😀]▓▓▓▓▓▓░░░░░░[🤖]
 totale   SMASH  barra    evoluzione
          attuale 0→100%  successiva
```

- **A sinistra il totale in kg** (unità fissa), con i decimali per restare corto:
  `0,30 kg` → `1,25 kg` → `12,4 kg` → `150 kg` → `1.500 kg`.
- **Barra da 0 a 100%** verso la prossima evoluzione.
- **Solo le teste**: a sinistra la testa di SMASH attuale, a destra la **testa dell'evoluzione nel
  suo colore vero** (non un punto interrogativo né un'ombra). Nella simulazione era azzurra come prova.
- Con SMASH spento: tutto in grigio + SMASH addormentato 💤 (vedi sezione 5).

**Home:** livello di SMASH e la stessa barra verso la prossima evoluzione, vicino al logo.

## 7. Condivisione

Card da postare, es. "Il mio SMASH ha divorato 1.230 kg di macerie", con SMASH al suo livello
e link all'app. Marketing gratis.

## 8. Non perdere il contatore (senza account)

Cosa salvare: totale macerie (in grammi), livelli già raggiunti, data del primo e dell'ultimo taglio.
Sono pochi byte.

**Regola d'oro: il contatore non scende mai.** Quando arrivano due valori (telefono e copia nel
cloud, oppure due dispositivi) si tiene sempre **il più alto**. Così un ripristino vecchio non
cancella i progressi.

| Situazione | Come si salva |
|---|---|
| Aggiornamento dell'app | memoria del telefono (già oggi) |
| Disinstalla e reinstalla, telefono nuovo **iPhone → iPhone** | **iCloud** (archivio chiave-valore): sincronizza da solo tra i dispositivi Apple dello stesso utente, nessun login |
| Disinstalla e reinstalla, telefono nuovo **Android → Android** | **backup Google** (Block Store + backup automatico): ripristino automatico con lo stesso account Google |
| Cambio **iPhone ↔ Android**, oppure webapp | **codice di recupero** (vedi sotto) |

Note:
- Il backup automatico Android avviene circa una volta al giorno: l'ultimo giorno di macerie
  potrebbe mancare. Block Store è più immediato: si usano entrambi.
- **Webapp:** Safari cancella i dati dei siti non usati per 7 giorni (salvo app aggiunta alla
  schermata Home). Nella webapp il contatore è fragile: serve il codice di recupero.

**Cosa è automatico:** memoria locale, iCloud (se l'utente ha iCloud attivo, quasi sempre),
backup Google + Block Store con ripristino alla reinstallazione (se il backup Google è attivo, di
base lo è) e la regola del valore più alto. **Unico passaggio manuale:** il codice di recupero.

**Codice di recupero** (per cambio piattaforma e webapp):
- dalla schermata di SMASH: "Salva i miei progressi" → un codice corto (o QR) da conservare;
- sull'altro dispositivo: "Ho un codice" → si inserisce e il contatore riparte da lì (si tiene il
  valore più alto);
- per non farlo dimenticare l'app lo **propone con discrezione** al momento giusto, per esempio
  "Salva i tuoi progressi" **dopo un'evoluzione** (una proposta, senza insistere);
- il codice contiene il totale e una firma dell'app, per scoraggiare codici inventati.
  Barare non fa guadagnare nulla di a pagamento (le evoluzioni sono gratis), quindi basta questo.

**Deciso (25 nov): niente login.** Si usano tutti i salvataggi qui sopra (memoria locale, iCloud,
backup Google + Block Store, regola del valore più alto, codice di recupero).
Un accesso con Apple / Google richiederebbe Firebase (login + database), configurazione dei login,
informativa privacy aggiornata, "Accedi con Apple" obbligatorio su iPhone se c'è Google e un tasto
per eliminare l'account: troppo per il solo caso del cambio piattaforma. Si valuta solo se in futuro
servirà per altro (es. classifiche o funzioni online).

L'acquisto "a vita" è a parte: si recupera sempre con "Ripristina acquisti" dello store.

Annullare un taglio **non** toglie le macerie (SMASH le ha già mangiate).

## 9. Monetizzazione

- Il contatore funziona anche nella versione **gratis con pubblicità** (fa tornare le persone).
- Le evoluzioni **non si comprano mai**, si guadagnano.
- Con l'**acquisto a vita** si possono sbloccare **skin extra** di SMASH (es. "SMASH Founder").

## 10. Grafica da preparare

Per ogni forma di SMASH: le 18 immagini dell'animazione + testa (interruttore) + miniatura;
più i 5 oggetti da cantiere e i cubetti.

Due strade:
- **A.** Disegni nuovi per ogni forma (risultato migliore, tanto lavoro);
- **B.** Forme ottenute dall'app modificando lo SMASH di oggi (colori titanio/oro, riflessi, aura): subito disponibili, meno spettacolari.

Si può partire con B e sostituire poi con i disegni veri.

---

## Decisioni prese

- Idea approvata, da sviluppare **su una copia** dell'app; l'app attuale resta com'è.
- Misura fisica credibile (volume reale delle demolizioni), mostrata come **peso in kg**.
- Livelli legati a **oggetti reali da cantiere**.
- SMASH spento comunicato **solo con il linguaggio visivo** (sezione 5).
- Evoluzioni **non a pagamento**; skin extra legate all'acquisto a vita.
- La prima evoluzione deve **costare lavoro** (soglie più alte del blocco 10 cm).
- Blocco **5 cm** e soglie confermate: tappa 15 kg; evoluzioni a 150 kg, 450 kg, 1.500 kg, 4.500 kg.
- Unità: **peso in kg**, sempre la stessa (densità 1,5 t/m³).
- Gli oggetti da cantiere sono **obiettivi** ("Riempi una carriola"), **non** i nomi delle skin.
- Nomi skin: demenziali, corti, comprensibili in tutte le lingue.
  - **Confermata: SMASH Burp** (obiettivo: riempi una carriola). Non dà il pugno: **distrugge con un
    rutto dall'eco distruttivo** (onde d'urto ad anelli che si allargano e frantumano la porzione,
    scritta da fumetto "BURP" con eco; eventuale suono originale, sempre breve e saltabile).
  - Proposte ancora da confermare: SMASH Disco (betoniera), SMASH Pew Pew con **vista laser e visore
    orizzontale** (cassone), SMASH Mamma Mia (camioncino). Altre idee: Yummy, Boing, Bonk, Banana.
  - Il visore è uno stile generico da robot: il film resta solo un ammiccamento, mai nominato.
- Skin a vita: **SMASH Tycoon, arancione, con il balletto** (nome neutro, parodia nel movimento, niente musica).
- **Collezione skin:** la nuova skin si indossa da sola all'evoluzione; in "Collezione" si vedono tutte (le bloccate con lucchetto e quanto manca) e si sceglie quella da usare.
- Contatore protetto **senza login**: locale + iCloud + backup Google/Block Store + valore più alto + codice di recupero.
- Testa dell'evoluzione mostrata **a colori** (il suo colore vero) a destra della barra.
- Contatore compatto: totale con **max 3 cifre** (unità e decimali scalano), **barra 0–100%** tra la
  testa di SMASH attuale (sinistra) e quella dell'evoluzione (destra).

## Domande aperte

1. Nomi e aspetto delle forme di SMASH per livello (nomi propri del personaggio, non gli oggetti da cantiere).
2. Grafica: disegni nuovi o forme modificate dall'app per partire.

## Registro

- **25 nov 2026:** nata l'idea; prime proposte (km → metri cubi, spessore blocco, oggetti da cantiere, SMASH spento solo visivo).
  Un primo tentativo di implementarla direttamente nell'app è stato **annullato e ripristinato**
  (nessuna modifica arrivata su GitHub o nella pagina di prova): si lavorerà solo su una copia.
- **25 nov 2026:** soglie giudicate troppo basse → proposta blocco 5 cm con prima evoluzione a 100 L
  (~200 tagli) e tappe intermedie senza evoluzione. Definito il contatore compatto: totale con max
  3 cifre, barra 0–100% tra testa attuale e testa dell'evoluzione.
- **25 nov 2026:** la scala ×10 portava l'ultimo livello a ~200.000 tagli (troppo). Nuova scala più
  dolce: 100 L, 300 L, 1 m³, 3 m³ (ultima evoluzione ≈ 6.000 tagli).
- **25 nov 2026:** confermati blocco 5 cm e scala 100 L / 300 L / 1 m³ / 3 m³.
- **25 nov 2026:** definito come non perdere il contatore: memoria locale + iCloud (iPhone) +
  backup Google/Block Store (Android), regola "si tiene sempre il valore più alto", codice di
  recupero per cambio piattaforma e webapp; account online rimandato.
- **25 nov 2026:** vista la simulazione del contatore (cubetti, "+…", contachilometri, barra, SMASH
  spento con tooltip e avviso una tantum). Decisi: unità **peso in kg** fissa (niente cambi di unità),
  soglie 15 / 150 / 450 / 1.500 / 4.500 kg, testa dell'evoluzione a colori invece del "?".
- **25 nov 2026:** deciso di restare senza login (niente Firebase): si attivano tutti i salvataggi senza account.
- **25 nov 2026:** confermato il piano salvataggi; il codice di recupero viene proposto con discrezione dopo le evoluzioni.
- **25 nov 2026:** definita la collezione delle skin (cambio automatico all'evoluzione, scelta libera tra le sbloccate).
- **25 nov 2026:** vista la simulazione della Collezione: ok; gli oggetti da cantiere diventano l'obiettivo ("Riempi una carriola"), non il nome della skin.
- **25 nov 2026:** proposti nomi skin internazionali; la skin dell'acquisto a vita sarà "SMASH Trump" arancione (rischio store da verificare, riserva "SMASH Tycoon").
- **25 nov 2026:** SMASH Trump confermato con la lettura "trump card" e nessun altro riferimento; SMASH Tycoon di riserva.
- **25 nov 2026:** skin a vita definitiva: SMASH Tycoon arancione con il balletto (scartato SMASH Trump).
- **25 nov 2026:** dopo l'evoluzione si apre la Collezione (chiudibile con X o "Continua a tagliare"); per far capire che si tocca: freccetta ›, pallino rosso per skin nuove, suggerimento una tantum al primo uso.
- **25 nov 2026:** ritocchi: Collezione aperta da sola solo alla prima evoluzione; mai nel mezzo di pannello/posizionamento/salvataggio; suggerimento dopo il primo taglio con SMASH.
- **25 nov 2026:** confermata SMASH Burp (distrugge con un rutto dall'eco distruttivo); scartati Crunch/Turbo/Kaboom/XXL; proposte Disco, Pew Pew (vista laser), Mamma Mia.
- **25 nov 2026:** definito il metodo skin (18 PNG del personaggio + effetto porzione fatto dall'app) e proposta la rosa dei personaggi (Boing, Inferno, Mamma Mia).
