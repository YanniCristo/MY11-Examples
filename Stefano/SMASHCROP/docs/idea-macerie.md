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

### ⚠️ Da decidere: spessore del blocco e soglie

Nella prima proposta (blocco 1 cm) il cassone da 1 m³ richiedeva ~10.000 tagli.
Con blocco 10 cm ("mattone") le soglie sono sembrate **troppo basse** (1 L al primo taglio).

Opzioni sul tavolo:

**A. Blocco 10 cm, soglie alzate** (fascia tipica ≈ 1 L, A4 intero ≈ 6 L)

| Soglia | Oggetto | Tagli circa |
|---|---|---|
| 10 L | secchio | 10 |
| 100 L | carriola | 100 |
| 1 m³ | cassone | 1.000 |
| 10 m³ | camion | 10.000 |
| 100 m³ | palazzina demolita | 100.000 |

**B. Blocco 2 cm, stessi oggetti** (fascia tipica ≈ 0,2 L)
secchio ~50 tagli, carriola ~500, cassone ~5.000.

Ritmo con ~10 tagli a settimana:
- A: secchio ~1 settimana, carriola ~2–3 mesi, cassone ~2 anni;
- B: secchio ~5 settimane, carriola ~1 anno, cassone molti anni.

Variante: A con il secchio a 25 L.
**Domanda aperta:** in quanto tempo un utente normale deve arrivare alla prima evoluzione (una settimana, un mese, di più)?

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

## 6. Dove si vede

- **Editor:** piccolo contatore in un angolo del riquadro (icona macerie + valore, es. "12,4 L").
- **Home:** livello di SMASH e barra verso la prossima evoluzione, vicino al logo.

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

## Domande aperte

1. Spessore del blocco e soglie (A, B o A con secchio a 25 L); tempo desiderato per la prima evoluzione.
2. Nomi e aspetto delle forme di SMASH per livello.
3. Grafica: disegni nuovi o forme modificate dall'app per partire.

## Registro

- **25 nov 2026:** nata l'idea; prime proposte (km → metri cubi, spessore blocco, oggetti da cantiere, SMASH spento solo visivo).
  Un primo tentativo di implementarla direttamente nell'app è stato **annullato e ripristinato**
  (nessuna modifica arrivata su GitHub o nella pagina di prova): si lavorerà solo su una copia.
