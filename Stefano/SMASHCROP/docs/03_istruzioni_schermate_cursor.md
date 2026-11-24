MYCROP — ISTRUZIONI PER CURSOR

Interpretazione delle 9 schermate grafiche e realizzazione dell’interfaccia Flutter

Le immagini numerate da 01 a 09 rappresentano i riferimenti visivi per costruire l’interfaccia dell’app MYCROP.

ATTENZIONE: NON SONO SCHERMATE DEFINITIVE DA COPIARE PIXEL PER PIXEL.

Le immagini sono state generate per illustrare le funzioni dell’applicazione e possono contenere errori grafici, proporzioni sbagliate, elementi incoerenti, pulsanti posizionati male e soluzioni poco intuitive.

Il tuo compito è interpretarle intelligentemente e trasformarle in un’interfaccia Flutter professionale, realmente utilizzabile e coerente con il Master Development Prompt.

REGOLA PRINCIPALE

In caso di conflitto tra i riferimenti, rispetta questo ordine di priorità:

1. Master Development Prompt: definisce le funzioni e i comportamenti obbligatori.
2. Schermate originali approvate: definiscono identità grafica, organizzazione generale e proporzioni.
3. Nuove immagini numerate: illustrano stati e funzionalità da implementare, ma possono contenere errori.
4. Migliori pratiche UX/UI: servono a correggere problemi di spazio, proporzioni, leggibilità e interazione.

Non introdurre nuove funzionalità soltanto perché un elemento compare accidentalmente in un’immagine.

Non copiare errori grafici per ottenere una somiglianza superficiale.

Non eliminare funzionalità già approvate per rendere l’interfaccia più simile ai mockup.

L’obiettivo è costruire la migliore versione funzionale di MYCROP, non riprodurre ogni imperfezione delle immagini.

⸻

01 — HOME SCREEN

Funzione: schermata iniziale dell’app.

Elementi da conservare:

* Logo MYCROP.
* Titolo Editor.
* Grafica futuristica con città illuminata al neon.
* Dimostrazione PRIMA/DOPO con due documenti.
* Personaggio SMASH con il pollice alzato.
* Testo principale: “Rimuovi ciò che non serve.”
* Testo descrittivo.
* Load Image.
* Load PDF.

La grafica centrale mostra un PDF con una porzione contenente tabella e grafico che viene rimossa.

Il documento di destra deve rappresentare il vero risultato ottenuto eliminando quella specifica sezione e ricongiungendo i due blocchi di testo.

Correzioni da applicare:

La home non deve diventare eccessivamente complessa.

La grafica futuristica è decorativa e non deve compromettere la leggibilità.

Il prima/dopo deve comunicare immediatamente la funzione principale dell’app.

I due pulsanti di importazione devono essere grandi, chiari e facilmente raggiungibili.

Usa l’immagine originale approvata come riferimento prioritario per questa schermata.

⸻

02 — EDITOR IMMAGINE, TAGLIO ORIZZONTALE

Funzione: schermata principale dopo il caricamento di un’immagine.

La fotografia o lo screenshot importato deve occupare la maggior parte dello spazio disponibile.

Elementi obbligatori:

* MYCROP.
* Condividi.
* Salva.
* Undo.
* Redo.
* Zoom 1.0x e relativo slider.
* Immagine visualizzata proporzionalmente.
* Due linee orizzontali A/B.
* Area da eliminare oscurata parzialmente.
* Rimuovi porzione.
* Orizzontale.
* Verticale.
* SMASH ON/OFF.
* Load Image.
* Load PDF.

Correzioni:

Orizzontale deve essere selezionato in rosso.

Verticale deve essere inattivo.

Le maniglie A/B devono essere coerenti con la direzione di movimento: in questa modalità si muovono verticalmente.

La maniglia A parte dal lato sinistro della propria linea.

La maniglia B parte dal lato destro.

La selezione oscurata deve lasciare visibile il contenuto sottostante.

Non inserire etichette superflue all’interno della fascia.

Le linee devono estendersi lungo la larghezza dell’immagine, non oltre il documento.

Il pulsante Rimuovi porzione deve occupare un’intera riga.

La riga successiva contiene Orizzontale, Verticale e SMASH.

La riga inferiore contiene Load Image e Load PDF.

Non spostare arbitrariamente questi comandi.

⸻

03 — EDITOR IMMAGINE, TAGLIO VERTICALE

Funzione: selezionare una fascia verticale da eliminare.

L’interfaccia è identica alla schermata 02.

Cambia soltanto la modalità di selezione.

* Verticale è selezionato in rosso.
* Orizzontale è inattivo.
* Le due linee diventano verticali.
* La fascia oscurata si trova tra le due linee verticali.
* Le linee A e B si muovono indipendentemente da sinistra a destra.

Le maniglie devono indicare correttamente il movimento orizzontale.

La maniglia A deve partire nella parte alta della propria linea, mentre B nella parte bassa.

ATTENZIONE: alcuni mockup rappresentano le maniglie con orientamento, forma o frecce sbagliate.

Correggili seguendo le specifiche del Master Prompt.

Non duplicare le maniglie e non aggiungere ulteriori indicatori di movimento.

Non cambiare la struttura generale dell’editor.

⸻

04 — DOPO IL TAGLIO E NUOVA SELEZIONE

Funzione: dimostrare il comportamento continuativo di MYCROP.

Questa schermata rappresenta il momento successivo alla rimozione di una fascia.

La sequenza corretta è:

1. L’utente preme Rimuovi porzione.
2. La sezione selezionata viene eliminata realmente.
3. I lembi conservati si avvicinano.
4. Le due parti si ricongiungono completamente.
5. Il risultato rimane pulito per circa 0,6 secondi.
6. Ricompare automaticamente una nuova selezione A/B.

Il timer parte soltanto dal completo ricongiungimento dei lembi.

Questa regola vale sia con SMASH attivo sia con SMASH disattivato.

La nuova selezione mantiene l’orientamento utilizzato per il taglio precedente.

Correzione essenziale:

Non utilizzare il mockup per determinare i pixel che devono scomparire.

Il risultato deve provenire dal vero motore di taglio, non da una ricostruzione grafica.

La nuova fascia deve essere collocata in una posizione utile e valida rispetto all’immagine modificata.

Non aggiungere messaggi o pulsanti per riattivare la selezione.

⸻

05 — EDITOR PDF

Funzione: editing di un documento PDF, anche multipagina.

Questa schermata deve conservare lo stesso sistema grafico dell’editor immagini.

Elementi specifici del PDF:

* Documento visibile nel viewport.
* Navigatore compatto con frecce.
* Testo come “Pag. 2 di 4”.
* Piccolo pulsante Layout PDF.
* Linee A/B.
* Ombreggiatura della sezione da rimuovere.

Il documento può avere qualsiasi formato.

Non assumere che sia A4.

Correzioni importanti:

La presenza del navigatore e del pulsante Layout non deve ridurre eccessivamente lo spazio destinato al documento.

Evita di aggiungere nuove barre permanenti se puoi integrare i controlli in una riga compatta.

Il pulsante Layout deve aprire soltanto le impostazioni di impaginazione PDF.

Salva e Condividi continuano ad avere le rispettive funzioni originali.

Il PDF deve essere sempre visualizzato senza deformazioni.

⸻

06 — SCELTA LAYOUT PDF

Funzione: decidere come disporre il contenuto dopo il taglio.

Esistono esattamente quattro modalità, in questo ordine:

1. Centrato
2. In alto
3. Riduci pagina
4. Personalizza posizione

Non creare altre modalità.

Centrato

Mantiene le dimensioni originali del foglio.

Il contenuto ricongiunto viene centrato nello spazio disponibile, senza modificare le proprie dimensioni.

In alto

Mantiene le dimensioni originali del foglio.

Il contenuto viene posizionato in alto, lasciando l’eventuale spazio libero nella parte inferiore.

Per tagli verticali applica il corrispondente allineamento iniziale a sinistra.

Riduci pagina

Riduce realmente le dimensioni del foglio per adattarle al contenuto ricongiunto.

Non deve limitarsi a rimpicciolire graficamente il contenuto all’interno del foglio originale.

Personalizza posizione

Mantiene le dimensioni originali del foglio e del contenuto.

Permette di trascinare il contenuto per scegliere dove collocarlo.

Non permette di ridimensionarlo.

Correzioni UX:

Non utilizzare necessariamente quattro schede gigantesche.

Se su uno smartphone piccolo le anteprime risultano troppo strette, organizza le opzioni in una griglia 2×2 o in un elenco compatto.

La priorità è rendere comprensibili le quattro modalità.

Il pannello deve essere temporaneo e richiudibile.

Dopo la conferma, il foglio deve tornare a occupare il massimo spazio disponibile.

Non lasciare un pannello Layout permanentemente aperto.

⸻

07 — PERSONALIZZA POSIZIONE

Funzione: posizionare manualmente il contenuto ricongiunto dentro il foglio PDF.

Questa schermata deve essere progettata con particolare attenzione.

Il comportamento obbligatorio è:

1. Mostrare il foglio originale.
2. Mostrare il contenuto ricongiunto, già ridotto nella dimensione interessata dal taglio.
3. Consentire all’utente di trascinare direttamente il contenuto.
4. Mostrare in tempo reale la posizione raggiunta.
5. Impedire che il contenuto esca dai confini validi del foglio.
6. Confermare con il pulsante Conferma posizione.

Deve essere disponibile anche Annulla.

Non sono consentiti:

* Ridimensionamento del contenuto.
* Maniglie agli angoli per cambiare grandezza.
* Pinch-to-resize.
* Modifica dell’aspect ratio.
* Rotazione del contenuto.
* Freccette direzionali come controllo principale.

L’utente deve semplicemente appoggiare il dito sul contenuto e trascinarlo.

Il movimento può avvenire sugli assi nei quali esiste spazio libero, senza cambiare dimensione.

Per un semplice taglio orizzontale, normalmente il movimento utile è verticale.

Se il contenuto è stato ridotto anche in larghezza, deve poter essere posizionato anche orizzontalmente.

Conferma posizione registra la scelta e chiude questa modalità.

Non utilizzare il pulsante Salva generale per confermare il posizionamento.

La modalità deve avere un’interfaccia pulita e lasciare ampio spazio alla visualizzazione del foglio.

⸻

08 — PDF MULTIPAGINA

Funzione: permettere layout diversi per pagine diverse dello stesso PDF.

Esempio:

* Pagina 1: Centrato.
* Pagina 2: In alto.
* Pagina 3: Riduci pagina.
* Pagina 4: Personalizza posizione.

Ogni pagina conserva indipendentemente:

* Tagli eseguiti.
* Dimensioni risultanti.
* Modalità di impaginazione.
* Posizione personalizzata, quando presente.

Il navigatore consente di passare da una pagina all’altra.

La configurazione della pagina corrente non deve modificare automaticamente le altre.

Correzioni UX importanti:

Il mockup contiene elementi esplicativi che non devono diventare necessariamente componenti permanenti dell’app.

Non aggiungere una barra di miniature sempre visibile.

Non introdurre un nuovo pannello di gestione pagine se non necessario.

La navigazione principale deve rimanere semplice:

← Pag. 2 di 4 →

Il pulsante Layout PDF permette di modificare la modalità della pagina corrente.

Se si desidera mostrare una panoramica delle pagine, deve essere un pannello temporaneo, non una parte fissa dell’editor.

Mantieni il massimo spazio per il PDF.

⸻

09 — IMMAGINE PULITA, SENZA SELEZIONE

Funzione: permettere all’utente di osservare il risultato senza linee e sovrapposizioni.

Questa schermata rappresenta lo stato in cui l’utente ha disattivato la modalità di selezione premendo nuovamente il pulsante già attivo.

Devono scomparire:

* Linea A.
* Linea B.
* Maniglia A.
* Maniglia B.
* Ombreggiatura della fascia.

L’immagine deve rimanere completamente visibile.

Non modificare il contenuto.

Non cambiare zoom o posizione del documento.

Orizzontale e Verticale devono apparire inattivi.

Il pulsante Rimuovi porzione deve essere disabilitato funzionalmente, perché non esiste una selezione attiva.

Premendo nuovamente Orizzontale o Verticale, l’utente riattiva la selezione corrispondente.

Le coordinate precedenti devono essere conservate quando ancora valide.

⸻

REGOLE GENERALI DI INTERFACCIA

1. Massimo spazio al documento

La priorità assoluta è la visualizzazione dell’immagine o del PDF.

La schermata deve funzionare anche con screenshot 9:16 e documenti molto lunghi.

Non comprimere il documento per fare spazio a elementi decorativi.

2. Coerenza tra schermate

Non cambiare posizione, colore o stile dei controlli senza una ragione funzionale.

La struttura dell’editor deve essere condivisa tra immagini e PDF.

3. Pulsanti con una sola responsabilità

* Salva: salva/esporta.
* Condividi: condivide.
* Undo: annulla.
* Redo: ripristina.
* Orizzontale: attiva/nasconde selezione orizzontale.
* Verticale: attiva/nasconde selezione verticale.
* SMASH: attiva/disattiva il personaggio.
* Layout PDF: apre le quattro opzioni di impaginazione.
* Rimuovi porzione: esegue il taglio.
* Load Image: importa immagine.
* Load PDF: importa PDF.
* Conferma posizione: conferma il posizionamento manuale.

Non creare menu nascosti dentro pulsanti che hanno già una funzione chiara.

4. SMASH

Utilizza esclusivamente gli asset originali forniti.

SMASH entra da sinistra, colpisce l’epicentro della sezione selezionata, distrugge la fascia ed esce a destra.

Le porzioni conservate si ricongiungono correttamente.

L’animazione rimane confinata al viewport.

La selezione riappare automaticamente dopo 0,5–0,8 secondi dal completo ricongiungimento, indipendentemente dall’attivazione di SMASH.

5. Interfaccia responsive

Utilizza dimensioni logiche Flutter, SafeArea, LayoutBuilder e vincoli responsive appropriati.

Non riprodurre le dimensioni dei mockup come valori assoluti universali.

Non deformare immagini o documenti.

Non usare le schermate di riferimento come sfondi statici.

Ricostruisci pulsanti, pannelli, selezioni e controlli come veri widget Flutter.

6. Interpretazione intelligente dei mockup

Quando un’immagine contiene un errore, non riprodurlo.

Quando un controllo sembra incoerente con il suo comportamento, correggilo.

Quando una soluzione occupa troppo spazio, ottimizzala.

Quando le proporzioni non sono realistiche, usa quelle corrette del dispositivo.

Quando un’immagine mostra un risultato di taglio non geometricamente corretto, ignora il risultato visivo e usa il motore di taglio reale.

Quando una schermata rappresenta troppi elementi contemporaneamente, separa correttamente gli stati temporanei da quelli permanenti.

Non inventare nuove funzioni per compensare un mockup sbagliato.

⸻

RISULTATO ATTESO

Realizza un’interfaccia Flutter che conservi l’identità visiva delle schermate di riferimento, ma che corregga autonomamente errori, incoerenze e soluzioni poco fluide.

Voglio un’app:

* Visivamente coerente.
* Professionale.
* Mobile-first.
* Semplice da comprendere.
* Rapida per tagli consecutivi.
* Adatta a immagini e PDF.
* Con il massimo spazio possibile per il contenuto.
* Con controlli realmente funzionanti.

Prima di implementare ciascuna schermata, confrontala con il Master Development Prompt.

Se un elemento grafico non è previsto dalle specifiche, non trasformarlo automaticamente in una nuova funzione.

Se una scelta visiva è ambigua, applica la soluzione UX più semplice che rispetti le funzioni approvate.

L’obiettivo non è copiare nove immagini: è costruire una sola applicazione coerente utilizzando le nove immagini per capire come devono apparire i suoi diversi stati.