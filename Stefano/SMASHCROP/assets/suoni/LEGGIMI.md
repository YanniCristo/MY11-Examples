# Suoni di SmashCrop (idea macerie)

Tutti mono, 44,1 kHz, AAC, volume uniformato a -16 LUFS, meno di 2,5 secondi.

| File | Uso | Origine |
|---|---|---|
| colpo_smash_1…4.m4a | pugno di SMASH sulla fascia, uno a caso | ElevenLabs Sound Effects |
| pop_popcorn_1…4.m4a | colpo di Popcorn (raffica di pop, accorciata a ~1,5 s), uno a caso | ElevenLabs Sound Effects |
| pling_barra.m4a | i pezzi arrivano alla barra (prima c'era `gnam_barra`, tolto: sembrava una scorreggia) | sintetizzato (`sintesi_suoni.py`, `pling()`) |
| rutto_burp_1…4.m4a | colpo di Burp: l'app ne sceglie uno a caso a ogni taglio, così non è sempre uguale | ElevenLabs Sound Effects (account di Stefano, non condiviso) |
| scorreggia_tycoon_1…4.m4a | colpo di Tycoon ("prrrt" + onda d'urto), uno a caso a ogni taglio | ElevenLabs Sound Effects |
| mammamia_1…4.m4a | colpo di Mamma Mia ("Mamma mia!"), uno a caso a ogni taglio | ElevenLabs Sound Effects |
| risata_muahaha_1…4.m4a | colpo di Muahaha (risata da robot cattivo), una a caso a ogni taglio | ElevenLabs Sound Effects |

Facoltativi, da fare quando serve: tintinnio dei pezzi che arrivano alla barra, fanfara dell'evoluzione.

Nell'app (mp3 in `SMASHCROP-macerie/app/assets/sounds`) tutti i suoni hanno il silenzio iniziale tolto, così partono esattamente al colpo; e vengono caricati in anticipo all'apertura dell'editor.
