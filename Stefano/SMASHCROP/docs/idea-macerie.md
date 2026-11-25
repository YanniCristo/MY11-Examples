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
- Un taglio è una superficie: per avere un volume si dà uno **spessore fisso al blocco** di macerie.
- Il contatore scala da solo: **cm³ → litri → m³**.
- Graficamente le macerie sono **cubetti** che cadono nel contatore (unità e animazione coincidono).

### Spessore e soglie

**Indicazione (25 nov):** le soglie con blocco 10 cm sono **troppo basse**. Con il primo SMASH
bisogna lavorare di più: l'utente deve **affezionarsi**, usare l'app più a lungo ed essere
**bramoso** di arrivare alla prima evoluzione.

**Proposta attuale (da confermare):** blocco **5 cm** (fascia tipica di un A4 ≈ 0,5 L; A4 intero ≈ 3 L).

| Soglia | Cosa succede | Tagli circa |
|---|---|---|
| 10 L | tappa: "Hai riempito un secchio!" (nessuna evoluzione) | ~20 |
| 100 L | **1ª evoluzione** – una carriola | ~200 |
| 300 L | **2ª evoluzione** – una betoniera | ~600 |
| 1 m³ | **3ª evoluzione** – un cassone | ~2.000 |
| 3 m³ | **4ª evoluzione** – un camioncino pieno | ~6.000 |

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

## 4. Animazioni (leggere, mai bloccanti)

- Dopo ogni taglio: cubetti che volano/cadono nel contatore, "+1,2 L", cifre che girano come un **contachilometri**.
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
 12,4 L  [😀]▓▓▓▓▓▓░░░░░░[🤖]
 totale   SMASH  barra    evoluzione
          attuale 0→100%  successiva
```

- **A sinistra il totale**, mai più di **3 cifre** (meglio 2) per non occupare spazio.
  Quando sale cambia unità e usa i decimali per restare corto:
  `850 cm³` → `1,2 L` → `12,4 L` → `124 L` → `1,24 m³` → `12,4 m³` → `124 m³`.
  (Regola: sempre 2–3 cifre significative; virgola come separatore, punto in inglese.)
- **Barra da 0 a 100%** verso la prossima evoluzione.
- **Solo le teste**: a sinistra della barra la testa di SMASH attuale, a destra quella dell'evoluzione.
  Idea da valutare: la testa dell'evoluzione in **ombra/silhouette** finché non la si raggiunge, per
  aumentare la curiosità.
- Con SMASH spento: tutto in grigio + SMASH addormentato 💤 (vedi sezione 5).

**Home:** livello di SMASH e la stessa barra verso la prossima evoluzione, vicino al logo.

## 7. Condivisione

Card da postare, es. "Il mio SMASH ha divorato 3,2 m³ di macerie", con SMASH al suo livello
e link all'app. Marketing gratis.

## 8. Salvataggio del contatore

Sul dispositivo, recuperabile reinstallando l'app, **senza account**:
- Android: backup automatico Google;
- iPhone: iCloud (key-value store).

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
- Misura in **metri cubi** (più credibile dei km: è la misura vera delle demolizioni).
- Livelli legati a **oggetti reali da cantiere**.
- SMASH spento comunicato **solo con il linguaggio visivo** (sezione 5).
- Evoluzioni **non a pagamento**; skin extra legate all'acquisto a vita.
- La prima evoluzione deve **costare lavoro** (soglie più alte del blocco 10 cm).
- Contatore compatto: totale con **max 3 cifre** (unità e decimali scalano), **barra 0–100%** tra la
  testa di SMASH attuale (sinistra) e quella dell'evoluzione (destra).

## Domande aperte

1. Confermare blocco 5 cm e soglie (1ª evoluzione a 100 L ≈ 200 tagli, ultima a 3 m³ ≈ 6.000 tagli).
2. Nomi e aspetto delle forme di SMASH per livello.
3. Grafica: disegni nuovi o forme modificate dall'app per partire.

## Registro

- **25 nov 2026:** nata l'idea; prime proposte (km → metri cubi, spessore blocco, oggetti da cantiere, SMASH spento solo visivo).
  Un primo tentativo di implementarla direttamente nell'app è stato **annullato e ripristinato**
  (nessuna modifica arrivata su GitHub o nella pagina di prova): si lavorerà solo su una copia.
- **25 nov 2026:** soglie giudicate troppo basse → proposta blocco 5 cm con prima evoluzione a 100 L
  (~200 tagli) e tappe intermedie senza evoluzione. Definito il contatore compatto: totale con max
  3 cifre, barra 0–100% tra testa attuale e testa dell'evoluzione.
- **25 nov 2026:** la scala ×10 portava l'ultimo livello a ~200.000 tagli (troppo). Nuova scala più
  dolce: 100 L, 300 L, 1 m³, 3 m³ (ultima evoluzione ≈ 6.000 tagli).
