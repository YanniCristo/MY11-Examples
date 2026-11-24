# SMASHCROP

App mobile (iOS e Android, Flutter) per **rimuovere sezioni interne** di immagini, screenshot e PDF, ricongiungendo automaticamente le parti rimaste. Mascotte: **SMASH**, il robot rosso che distrugge la fascia selezionata.

> I documenti in `docs/` sono stati scritti quando l'app si chiamava ancora **MYCROP**. Il nome è cambiato, le specifiche restano valide: dove leggi "MYCROP" intendi "SmashCrop".

## Decisioni prese

| Voce | Scelta |
|---|---|
| Nome sugli store | **SmashCrop PDF & Image** |
| Sottotitolo App Store | **Rimuovi sezioni di foto e PDF** (29/30 caratteri) |
| Nome dentro l'app | **SMASHCROP**: "SMASH" rosso + "CROP" bianco, tutto maiuscolo |
| Nome nei testi (store, descrizioni, notifiche) | **SmashCrop** |
| Icona | **3D** (`assets/branding/icon_3d_1024.png`); la flat resta come alternativa |
| Framework | Flutter / Dart, sviluppo con Cursor |

## Contenuto

```
docs/
  01_presentazione_progetto.md       concetto, funzioni ed esperienza utente
  02_master_development_prompt.md    specifica tecnica completa (priorità massima)
  03_istruzioni_schermate_cursor.md  come interpretare i mockup 01–09
design/
  reference/      le 2 interfacce approvate (home, editor): riferimento grafico prioritario
  mockups/        schermate 01–09: illustrano gli stati, possono contenere errori
  animation/      GIF di riferimento del movimento di SMASH (layout vecchio)
assets/
  branding/       icone 3D e flat (sorgente 1254 px + 1024 px per lo store), SMASH pollice alzato in alta risoluzione
  characters/smash/frames_hd/    18 frame HD rifatti (001–018): versione in uso
  characters/smash/frames_gif/   20 frame originali estratti dalla GIF (archivio)
```

Ordine di priorità in caso di conflitto: **Master Prompt → interfacce approvate → mockup 01–09 → buone pratiche UX**.

## Note sugli asset di SMASH

**Versione in uso: `frames_hd/`**, 18 frame rifatti in alta definizione:
- tela comune 901×1744, robot alto circa 250 px, piedi allineati a y≈1110;
- 006, 007, 008, 009 e 015 sono stati riscalati per uniformarli al resto della sequenza;
- alcuni frame sono un po' fuori modello (cresta rosa nell'011, sirena nel 012, braccio-cannone nel 018, occhi verdi nel 010). Si è scelto di tenerli così: l'animazione è veloce e non si notano;
- sequenza: entrata 001–003 · carica 004–005 · pugno 006–007 · detriti 008–009 · recupero 010–014 · pollice 015–016 · uscita 017–018;
- anteprima animata: `anteprima_frames_hd.gif`, a 12 fps.

I frame in `frames_gif/` sono l'archivio della versione vecchia:

- **Bassa risoluzione.** Il robot è alto circa 130 px; su iPhone ne servono 350–400.
- **Residui della schermata originale** in alcuni frame: "AU" nel 002, "5.5" e riquadri nell'008, linee rosse nel 009 e nel 012, puntini nel 006.
- **Posizioni fisse.** Ogni frame è una tela intera di 424×820 con il robot già posizionato. Nell'app vanno ritagliati attorno al robot e il movimento va gestito dal codice (l'epicentro dipende dalla fascia scelta).
- **Frame da scartare.** 000 e 019 sono vuoti; 001 e 018 sono tagliati al bordo. L'entrata e l'uscita si fanno via codice usando il 002 e il 017.

Sequenza: entrata 002–003 · carica 004–005 · pugno 006–007 · detriti 008–009 · recupero 010–014 · pollice 015–016 · uscita 017–018.

Nell'app i frame vanno comunque ritagliati attorno al robot, e il movimento (entrata, epicentro del pugno, uscita) va gestito dal codice.

## Impostazioni dell'animazione (scelte il 24/11/2026 dalla pagina di prova)

| Parametro | Valore |
|---|---|
| Velocità SMASH | 10 fotogrammi/s (il pollice alzato, frame 016, dura 3 fotogrammi; il 015 ne dura 2) |
| Dimensione SMASH | robot alto il 32% della larghezza del viewport |
| Durata ricongiungimento | 320 ms, curva ease-in-out |
| Pausa prima della nuova selezione | 0,80 s, contata dal ricongiungimento completato |
| Punto d'impatto nel frame | il pugno del frame 006 (in `frames_hd/`: x≈555, y≈975 sulla tela 901×1744) va sull'epicentro della fascia |
| Inizio del ricongiungimento | 2 fotogrammi dopo l'impatto |

**Maniglie A/B fuori dall'immagine.** In modalità orizzontale stanno a sinistra (A) e a destra (B) del documento; in verticale sopra (A) e sotto (B). Il viewport riserva un margine di 34 pt solo sull'asse dove si trovano le maniglie.

## Stato

- [x] Specifiche, mockup e asset raccolti
- [x] Nome, sottotitolo e icona decisi
- [ ] Milestone 1: progetto Flutter, tema, home, importazione file
- [ ] Milestone 2: motore di taglio e test
- [ ] Milestone 3–8: vedi `docs/02_master_development_prompt.md`, sezione 45
