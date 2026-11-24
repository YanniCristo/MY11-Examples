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
  characters/smash/frames_gif/   20 frame dell'animazione estratti dalla GIF
```

Ordine di priorità in caso di conflitto: **Master Prompt → interfacce approvate → mockup 01–09 → buone pratiche UX**.

## Note sugli asset di SMASH

I frame in `frames_gif/` sono **provvisori**:

- **Bassa risoluzione.** Il robot è alto circa 130 px; su iPhone ne servono 350–400.
- **Residui della schermata originale** in alcuni frame: "AU" nel 002, "5.5" e riquadri nell'008, linee rosse nel 009 e nel 012, puntini nel 006.
- **Posizioni fisse.** Ogni frame è una tela intera di 424×820 con il robot già posizionato. Nell'app vanno ritagliati attorno al robot e il movimento va gestito dal codice (l'epicentro dipende dalla fascia scelta).
- **Frame da scartare.** 000 e 019 sono vuoti; 001 e 018 sono tagliati al bordo. L'entrata e l'uscita si fanno via codice usando il 002 e il 017.

Sequenza: entrata 002–003 · carica 004–005 · pugno 006–007 · detriti 008–009 · recupero 010–014 · pollice 015–016 · uscita 017–018.

**Da fare:** rigenerare l'animazione partendo da `smash_thumbsup_hires.png` ed esportarla come video ad alta risoluzione, poi estrarre frame puliti che sostituiranno questi.

## Stato

- [x] Specifiche, mockup e asset raccolti
- [x] Nome, sottotitolo e icona decisi
- [ ] Milestone 1: progetto Flutter, tema, home, importazione file
- [ ] Milestone 2: motore di taglio e test
- [ ] Milestone 3–8: vedi `docs/02_master_development_prompt.md`, sezione 45
