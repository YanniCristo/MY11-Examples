# SmashCrop — versione con le macerie (copia di lavoro)

Copia separata dell'app SmashCrop con l'idea "SMASH mangia-macerie".
**L'app principale è in `../SMASHCROP/app` e non viene toccata da questa versione.**

Specifica completa: [`../SMASHCROP/docs/idea-macerie.md`](../SMASHCROP/docs/idea-macerie.md).

## Cosa c'è in più rispetto all'app principale

- **Contatore delle macerie** (kg, blocco 5 cm, 1,5 kg/L) in alto a sinistra nell'editor e nella home:
  totale, testa dello SMASH in uso, barra verso la prossima evoluzione, testa della prossima.
- **A ogni colpo**: gli elementi della skin esplodono dalla fascia, la maggior parte cade e sparisce
  sotto i pulsanti, 4 pezzi si fermano, si illuminano e volano a curva nel contatore ("gnam", "+kg").
- **6 personaggi**: SMASH, Burp (150 kg), Popcorn (450 kg), Muahaha (1.500 kg), Mamma Mia (4.500 kg),
  Tycoon (acquisto a vita, non ancora collegato). Tappa del secchio a 15 kg.
- **Evoluzione** a tutto schermo e **Collezione** animata (sagome per i bloccati, card da condividere).
- **Suoni** (4 varianti a caso per personaggio, seguono il silenzioso dell'iPhone) e **vibrazione**.
- **Menu ☰**: Collezione, suoni, vibrazione, Premium (in arrivo), codice di recupero, aiuto.
- **Codice di recupero** (12 caratteri con firma) per cambio telefono / webapp.

## Ancora da fare

- iCloud (archivio chiave-valore) e Google Block Store per il contatore senza codice.
- Acquisto a vita (Tycoon + niente pubblicità) e "Ripristina acquisti".
- Effetti diversi sulla porzione per ogni skin (oggi tutti usano la frantumazione + gli elementi).

Codice: `lib/features/rubble/` (contatore, skin, effetti, Collezione, menu).
Immagini e suoni: `assets/rubble/`, `assets/sounds/` (mp3).
