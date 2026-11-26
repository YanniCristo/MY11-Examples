# OctoSmash — pacchetto grafiche per ChatGPT

Idea per un **aggiornamento futuro** di SmashCrop (non fa parte dell'app di oggi).
OctoSmash è un robot-polpo della famiglia di SMASH: invece di distruggere una fascia,
**copre un rettangolo spruzzando inchiostro** nero o bianco.

## Cosa c'è qui dentro

| File | Cosa contiene |
|---|---|
| `01_istruzioni_comuni.md` | Regole da incollare **sempre** prima di ogni richiesta |
| `02_personaggi.md` | I 12 OctoSmash: aspetto, colori, come si sbloccano |
| `03_animazione_18_immagini.md` | La sceneggiatura delle 18 immagini (uguale per tutti) + i dettagli di ognuno |
| `04_teste_e_pose.md` | Testa, testa che dorme e posa da eroe di ogni OctoSmash |
| `05_elementi_inchiostro.md` | I 6 elementi d'inchiostro per il nero e per il bianco |
| `06_contenitori_inchiostro.md` | I 5 contenitori degli obiettivi (litri d'inchiostro) |
| `07_illustrazione_novita.md` | L'immagine del popup "Novità" |
| `riferimenti/` | Le 18 immagini di SMASH, testa, posa, obiettivi ed esempi di skin già fatte |

## Come usarlo con ChatGPT

1. Apri una chat nuova per **ogni** OctoSmash: così lo stile non si mescola.
2. Allega le **18 immagini** di `riferimenti/smash_18_immagini/` e la posa
   `riferimenti/altro/smash_posa_eroe.png`.
3. Incolla `01_istruzioni_comuni.md`, poi la scheda del personaggio da `02_personaggi.md`,
   poi la sceneggiatura da `03_animazione_18_immagini.md`.
4. **Ordine consigliato:** prima i due OctoSmash di partenza (Bianco e Nero). Quando sono
   approvati, allega le loro immagini come riferimento per le evoluzioni, al posto di SMASH.
5. Poi teste e pose (`04`), elementi (`05`), contenitori (`06`) e illustrazione (`07`).

## Riepilogo di cosa serve in totale

- 12 OctoSmash × (18 immagini + testa + testa che dorme + posa da eroe)
- 6 elementi d'inchiostro nero + 6 elementi d'inchiostro bianco
- 5 contenitori × 2 versioni (inchiostro nero / inchiostro bianco)
- 1 illustrazione per il popup "Novità"

Formati: **PNG con sfondo trasparente**, misure indicate in ogni file.
