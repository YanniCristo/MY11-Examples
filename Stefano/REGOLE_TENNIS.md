# Regole MY11 – Tennis

Valgono per ogni file di tennis. Si parte sempre da `Moduli altri sport/Riferimento_tennis.my11` (MED 2-0 COB sistemato da Stefano) e si cambiano solo nomi, immagini, loghi e titolo.

## Struttura
- Modulo `tn_1v1` (1 vs 1), campo da tennis del catalogo (`catalogStadiumId` `h68996830h`, immagine del campo inclusa nel file).
- **Vincitore in alto a sinistra** (`tn_tc`), **sconfitto in basso a destra** (`tn_bc`).
- **Logo sinistro** = bandiera della nazionalità del giocatore in alto; **logo destro** = bandiera del giocatore in basso (anche per chi gioca come neutrale si usa la bandiera del suo paese).
- Ogni formazione deve iniziare con `"format":"my11-formation","version":1`.

## Titolo
- Prime 3 lettere del cognome, maiuscole, con il risultato in set senza spazi: **`MED 2-0 COB`** (vincitore a sinistra).
- Il campo `name` resta in esteso (es. `MEDVEDEV 2-0 COBOLLI`).

## Slot (valori fissi presi dal riferimento)
| | tn_tc (alto) | tn_bc (basso) |
|---|---|---|
| pinnedCenters | 0.3462, 0.2617 | 0.6399, 0.8188 |
| slotPhotoScales | 2.127 | 2.127 |
| slotWidthScales / slotHeightScales | 1.45 / 1.45 | 1.45 / 1.45 |
| slotFontScales | 1.570 | 1.570 |
| slotLiveOverlayScales | 1.0 | 1.0 |

- Valori globali tutti a 1.0. `slotStyle` come nel riferimento (etichetta gialla, scritta scura).
- Etichetta = cognome in maiuscolo (es. `MEDVEDEV`).

## Immagini dei giocatori
- **Mezzobusto** (testa, spalle e busto), sfondo trasparente, circa 300×320 px, **base attaccata al fondo** dell'immagine.
- **Base immagini:** prima di chiedere foto, usare i mezzibusti già pronti in `Copia file Fulvio (con possibili modifiche)/Pics/ATP Giocatori/` (un PNG per giocatore, nome = etichetta, es. `SINNER.png`, `D.FOKINA.png`) o la cartella `Pics/ATP TENNIS PLAYERS.my11`. Etichette = solo cognome maiuscolo (nomi lunghi abbreviati: `D.FOKINA`, `A.-ALIASSIME`). Giocatori nuovi vanno aggiunti a entrambi.
- Le foto mancanti le fornisce Stefano; Claude le scontorna/ritaglia e le inserisce (Claude non scarica foto di atleti dal web).

## Banner MY11
- Banner "Created with MY11" come immagine libera, in basso a sinistra: centro `0.1889, 0.8705`, scala foto `2.032`.

## Anteprima
- Sfondo = campo da tennis, titolo giallo e bandiere nella barra nera in alto.
