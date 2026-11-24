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
  static const fileReady = 'File pronto';
  static const saveToGalleryHint =
      'Nel menu che si apre scegli «Salva immagine» per metterla in Galleria/Foto.';
  static const saveToFilesHint = 'Nel menu che si apre scegli «Salva su File».';
  static const saveToGallery = 'Salva in Galleria';
  static const saveToFiles = 'Salva in File';
  static const download = 'Scarica';

  /// Messaggio con l'errore tecnico tra parentesi, accorciato.
  static String withDetail(String msg, String? detail) {
    if (detail == null || detail.isEmpty) return msg;
    final d = detail.length > 160 ? '${detail.substring(0, 160)}…' : detail;
    return '$msg\n($d)';
  }

  static const largeTitle = 'PDF molto grande';
  static String largeBody(int mb) =>
      'Questo PDF pesa $mb MB. Nel browser del telefono potrebbe chiudersi '
      'per mancanza di memoria: per sicurezza usa l\'app. Se vai avanti, i '
      'tagli si salvano mentre lavori e puoi riprendere da dove eri.';
  static const openAnyway = 'Apri comunque';

  static const resumeTitle = 'Lavoro in sospeso';
  static String resumeBody(String name, int cuts) =>
      '$name · ${cuts == 1 ? '1 taglio' : '$cuts tagli'}';
  static const resumeHint = 'Per riprendere, scegli di nuovo lo stesso file.';
  static const resume = 'Riprendi';
  static const discard = 'Elimina';
  static String resumeWrongFile(String name) =>
      'Non è lo stesso file: per riprendere scegli «$name».';

  static const pdfOpening = 'Apro il PDF…';
  static const layoutPdf = 'Layout PDF';
  static const layoutTitle = 'Scegli layout del PDF';
  static const applyAndContinue = 'Applica e continua';
  static const placeContent = 'Posiziona il contenuto';
  static const layoutForNext = 'Usa questo layout anche per le prossime pagine';
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
