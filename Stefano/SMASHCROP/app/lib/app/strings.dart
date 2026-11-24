/// Testi dell'app. Tutti in un solo posto per la futura traduzione
/// (inglese, spagnolo, francese, tedesco, portoghese).
class S {
  const S._();

  static const appName = 'SmashCrop';
  static const editor = 'Editor';
  static const homeTitle = 'Rimuovi ciò che non serve.';
  static const homeSubtitle =
      'Seleziona una porzione, eliminala e unisci automaticamente il resto.';
  static const homeHint = 'Scegli un\'immagine o un documento PDF per iniziare';
  static const loadImage = 'Load Image';
  static const loadPdf = 'Load PDF';
  static const pdfPassword = 'Serve la password per aprire questo PDF.';
  static const pdfLocked =
      'Il proprietario di questo PDF non consente di modificarlo, quindi SmashCrop non può aprirlo.';
  static const passwordTitle = 'PDF protetto';
  static const passwordBody = 'Inserisci la password del documento.';
  static const passwordWrong = 'Password non corretta, riprova.';
  static const passwordHint = 'Password';
  static const open = 'Apri';
  static const pdfInvalid =
      'Non riesco ad aprire questo PDF. Il file potrebbe essere danneggiato.';
  static const pdfRenderFailed = 'Non riesco a mostrare questa pagina.';
  static const pdfSaved = 'PDF salvato';
  static const downloaded = 'File scaricato';
  static const pdfOpening = 'Apro il PDF…';
  static const layoutPdf = 'Layout PDF';
  static const layoutTitle = 'Scegli layout del PDF';
  static const applyAndContinue = 'Applica e continua';
  static const placeContent = 'Posiziona il contenuto';
  static const applyToAll = 'Applica a tutte le pagine modificate';
  static const applyToAllTitle = 'Applicare a tutte le pagine?';
  static String applyToAllBody(String mode) =>
      'Tutte le pagine già tagliate useranno "$mode". Le pagine con una posizione personalizzata la perderanno.';
  static const cancel = 'Annulla';
  static const apply = 'Applica';
  static const rasterNote =
      'Le pagine tagliate diventano immagini: il testo non sarà più selezionabile e '
      'le firme digitali non resteranno valide. Le pagine non tagliate restano intatte.';
  static const positionTitle = 'Personalizza posizione';
  static const positionHint =
      'Trascina il contenuto per scegliere dove metterlo nel foglio. La dimensione non cambia.';
  static const confirmPosition = 'Conferma posizione';
  static String pageOf(int page, int total) => 'Pag. $page di $total';

  static const share = 'Condividi';
  static const save = 'Salva';
  static const undo = 'Undo';
  static const redo = 'Redo';
  static const removePortion = 'Rimuovi porzione';
  static const horizontal = 'Orizzontale';
  static const vertical = 'Verticale';
  static const smash = 'SMASH';
  static const smashOn = 'SMASH attivo';
  static const smashOff = 'SMASH disattivato';

  static const saved = 'Immagine salvata nelle Foto';
  static const saveDenied =
      'Per salvare serve il permesso di accedere alle Foto. Puoi darlo dalle Impostazioni.';
  static const saveFailed = 'Salvataggio non riuscito. Riprova.';
  static const saveUnavailable =
      'Su questo dispositivo il salvataggio nelle Foto non è disponibile: usa Condividi.';
  static const shareFailed = 'Condivisione non riuscita. Riprova.';
  static const loadFailed =
      'Non riesco ad aprire questa immagine. Prova con un altro file.';
  static const tooLarge =
      'Immagine troppo grande: il lato massimo è di 16.000 pixel.';
  static const preparing = 'Preparo il file…';
  static const opening = 'Apro l\'immagine…';
}
