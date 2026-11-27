import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show ValueNotifier;

/// Lingue dell'app, con il nome scritto nella lingua stessa.
enum AppLang {
  it('Italiano'),
  en('English'),
  fr('Français'),
  es('Español'),
  pt('Português'),
  de('Deutsch');

  const AppLang(this.nativeName);
  final String nativeName;

  static AppLang? fromCode(String? code) {
    for (final l in values) {
      if (l.name == code) return l;
    }
    return null;
  }

  /// Lingua del dispositivo (la prima delle preferite che l'app conosce);
  /// se non si riesce a leggerla o non è tra queste, inglese.
  static AppLang device() {
    try {
      for (final loc in PlatformDispatcher.instance.locales) {
        final l = fromCode(loc.languageCode.toLowerCase());
        if (l != null) return l;
      }
    } catch (_) {}
    return AppLang.en;
  }
}

/// Testi dell'app in sei lingue. "Undo" e "Redo" restano uguali ovunque.
class S {
  const S._();

  /// Lingua in uso: cambiandola, l'app si ridisegna.
  static final ValueNotifier<AppLang> current = ValueNotifier(AppLang.en);
  static AppLang get lang => current.value;

  // ordine fisso: italiano, inglese, francese, spagnolo, portoghese, tedesco
  static String _t(
    String it,
    String en,
    String fr,
    String es,
    String pt,
    String de,
  ) => switch (lang) {
    AppLang.it => it,
    AppLang.en => en,
    AppLang.fr => fr,
    AppLang.es => es,
    AppLang.pt => pt,
    AppLang.de => de,
  };

  static const appName = 'SmashCrop';
  static String get editor =>
      _t('Editor', 'Editor', 'Éditeur', 'Editor', 'Editor', 'Editor');
  static String get homeTitle => _t(
    'Rimuovi ciò che non serve.',
    'Remove what you don\'t need.',
    'Supprimez ce qui ne sert pas.',
    'Elimina lo que no necesitas.',
    'Remova o que não serve.',
    'Entferne, was du nicht brauchst.',
  );
  static String get homeSubtitle => _t(
    'Seleziona una porzione, eliminala e unisci automaticamente il resto.',
    'Select a section, delete it and the rest joins up automatically.',
    'Sélectionnez une partie, supprimez-la et le reste se rejoint automatiquement.',
    'Selecciona una parte, elimínala y el resto se une automáticamente.',
    'Selecione uma parte, apague-a e o resto se une automaticamente.',
    'Wähle einen Bereich, lösche ihn und der Rest wird automatisch zusammengefügt.',
  );
  static String get homeHint => _t(
    'Scegli una o più immagini, oppure un PDF, per iniziare',
    'Choose one or more images, or a PDF, to start',
    'Choisissez une ou plusieurs images, ou un PDF, pour commencer',
    'Elige una o varias imágenes, o un PDF, para empezar',
    'Escolha uma ou mais imagens, ou um PDF, para começar',
    'Wähle ein oder mehrere Bilder oder ein PDF, um zu beginnen',
  );
  static String get demoDescription => _t(
    'Esempio: una tabella tra due paragrafi viene rimossa e i paragrafi si uniscono',
    'Example: a table between two paragraphs is removed and the paragraphs join up',
    'Exemple : un tableau entre deux paragraphes est supprimé et les paragraphes se rejoignent',
    'Ejemplo: se elimina una tabla entre dos párrafos y los párrafos se unen',
    'Exemplo: uma tabela entre dois parágrafos é removida e os parágrafos se unem',
    'Beispiel: Eine Tabelle zwischen zwei Absätzen wird entfernt und die Absätze werden zusammengefügt',
  );
  static String get loadImage => _t(
    'Carica immagini',
    'Load Images',
    'Ouvrir des images',
    'Cargar imágenes',
    'Carregar imagens',
    'Bilder laden',
  );
  static String get loadPdf => _t(
    'Carica PDF',
    'Load PDF',
    'Ouvrir un PDF',
    'Cargar PDF',
    'Carregar PDF',
    'PDF laden',
  );

  // --- lingua ----------------------------------------------------------------
  static String get languageTitle =>
      _t('Lingua', 'Language', 'Langue', 'Idioma', 'Idioma', 'Sprache');
  static String get languageAuto => _t(
    'Automatica',
    'Automatic',
    'Automatique',
    'Automático',
    'Automático',
    'Automatisch',
  );
  static String get languageDevice => _t(
    'Lingua del telefono',
    'Device language',
    'Langue de l\'appareil',
    'Idioma del dispositivo',
    'Idioma do dispositivo',
    'Gerätesprache',
  );

  // --- PDF: apertura e password -----------------------------------------------
  static String get pdfPassword => _t(
    'Serve la password per aprire questo PDF.',
    'A password is needed to open this PDF.',
    'Un mot de passe est nécessaire pour ouvrir ce PDF.',
    'Se necesita la contraseña para abrir este PDF.',
    'É necessária a senha para abrir este PDF.',
    'Zum Öffnen dieses PDFs ist ein Passwort nötig.',
  );
  static String get pdfLocked => _t(
    'Il proprietario di questo PDF non consente di modificarlo, quindi SmashCrop non può aprirlo.',
    'The owner of this PDF does not allow it to be edited, so SmashCrop cannot open it.',
    'Le propriétaire de ce PDF n\'autorise pas sa modification, SmashCrop ne peut donc pas l\'ouvrir.',
    'El propietario de este PDF no permite modificarlo, por eso SmashCrop no puede abrirlo.',
    'O proprietário deste PDF não permite editá-lo, por isso o SmashCrop não pode abri-lo.',
    'Der Eigentümer dieses PDFs erlaubt keine Bearbeitung, deshalb kann SmashCrop es nicht öffnen.',
  );
  static String get passwordTitle => _t(
    'PDF protetto',
    'Protected PDF',
    'PDF protégé',
    'PDF protegido',
    'PDF protegido',
    'Geschütztes PDF',
  );
  static String get passwordBody => _t(
    'Inserisci la password del documento.',
    'Enter the document\'s password.',
    'Saisissez le mot de passe du document.',
    'Introduce la contraseña del documento.',
    'Digite a senha do documento.',
    'Gib das Passwort des Dokuments ein.',
  );
  static String get passwordWrong => _t(
    'Password non corretta, riprova.',
    'Wrong password, try again.',
    'Mot de passe incorrect, réessayez.',
    'Contraseña incorrecta, inténtalo de nuevo.',
    'Senha incorreta, tente novamente.',
    'Falsches Passwort, versuch es noch einmal.',
  );
  static String get passwordHint => _t(
    'Password',
    'Password',
    'Mot de passe',
    'Contraseña',
    'Senha',
    'Passwort',
  );
  static String get open =>
      _t('Apri', 'Open', 'Ouvrir', 'Abrir', 'Abrir', 'Öffnen');
  static String get pdfInvalid => _t(
    'Non riesco ad aprire questo PDF. Il file potrebbe essere danneggiato.',
    'This PDF can\'t be opened. The file may be damaged.',
    'Impossible d\'ouvrir ce PDF. Le fichier est peut-être endommagé.',
    'No se puede abrir este PDF. Puede que el archivo esté dañado.',
    'Não foi possível abrir este PDF. O arquivo pode estar danificado.',
    'Dieses PDF lässt sich nicht öffnen. Die Datei ist möglicherweise beschädigt.',
  );
  static String get pdfRenderFailed => _t(
    'Non riesco a mostrare questa pagina.',
    'This page can\'t be displayed.',
    'Impossible d\'afficher cette page.',
    'No se puede mostrar esta página.',
    'Não foi possível mostrar esta página.',
    'Diese Seite kann nicht angezeigt werden.',
  );
  static String get pdfOpening => _t(
    'Apro il PDF…',
    'Opening PDF…',
    'Ouverture du PDF…',
    'Abriendo el PDF…',
    'Abrindo o PDF…',
    'PDF wird geöffnet…',
  );

  /// Messaggio con l'errore tecnico tra parentesi, accorciato.
  static String withDetail(String msg, String? detail) {
    if (detail == null || detail.isEmpty) return msg;
    final d = detail.length > 160 ? '${detail.substring(0, 160)}…' : detail;
    return '$msg\n($d)';
  }

  static String get largeTitle => _t(
    'PDF molto grande',
    'Very large PDF',
    'PDF très volumineux',
    'PDF muy grande',
    'PDF muito grande',
    'Sehr großes PDF',
  );
  static String largeBody(int mb) => _t(
    'Questo PDF pesa $mb MB. Nel browser del telefono potrebbe chiudersi '
        'per mancanza di memoria: per sicurezza usa l\'app. Se vai avanti, i '
        'tagli si salvano mentre lavori e puoi riprendere da dove eri.',
    'This PDF is $mb MB. The phone\'s browser may close it for lack of '
        'memory: to be safe, use the app. If you go ahead, your cuts are saved '
        'as you work and you can pick up where you left off.',
    'Ce PDF pèse $mb Mo. Le navigateur du téléphone pourrait se fermer par '
        'manque de mémoire : par sécurité, utilisez l\'app. Si vous continuez, '
        'vos découpes sont enregistrées au fur et à mesure et vous pourrez '
        'reprendre là où vous en étiez.',
    'Este PDF pesa $mb MB. El navegador del teléfono podría cerrarse por '
        'falta de memoria: por seguridad, usa la app. Si continúas, los '
        'recortes se guardan mientras trabajas y podrás retomar donde lo dejaste.',
    'Este PDF tem $mb MB. O navegador do celular pode fechar por falta de '
        'memória: por segurança, use o app. Se continuar, os cortes são salvos '
        'enquanto você trabalha e você pode retomar de onde parou.',
    'Dieses PDF ist $mb MB groß. Der Browser des Handys könnte sich wegen '
        'Speichermangel schließen: Nutze sicherheitshalber die App. Wenn du '
        'weitermachst, werden deine Schnitte laufend gespeichert und du kannst '
        'dort weitermachen, wo du warst.',
  );
  static String get openAnyway => _t(
    'Apri comunque',
    'Open anyway',
    'Ouvrir quand même',
    'Abrir de todos modos',
    'Abrir mesmo assim',
    'Trotzdem öffnen',
  );

  // --- lavoro in sospeso --------------------------------------------------------
  static String get resumeTitle => _t(
    'Lavoro in sospeso',
    'Unfinished work',
    'Travail en cours',
    'Trabajo pendiente',
    'Trabalho pendente',
    'Unfertige Arbeit',
  );
  static String resumeBody(String name, int cuts, [int removed = 0]) {
    if (removed > 0) {
      final pages = _t(
        removed == 1 ? 'pagina tolta' : 'pagine tolte',
        removed == 1 ? 'page removed' : 'pages removed',
        removed == 1 ? 'page retirée' : 'pages retirées',
        removed == 1 ? 'página quitada' : 'páginas quitadas',
        removed == 1 ? 'página removida' : 'páginas removidas',
        removed == 1 ? 'Seite entfernt' : 'Seiten entfernt',
      );
      final base = cuts > 0 ? resumeBody(name, cuts) : name;
      return '$base · $removed $pages';
    }
    final one = cuts == 1;
    final word = _t(
      one ? 'taglio' : 'tagli',
      one ? 'cut' : 'cuts',
      one ? 'découpe' : 'découpes',
      one ? 'recorte' : 'recortes',
      one ? 'corte' : 'cortes',
      one ? 'Schnitt' : 'Schnitte',
    );
    return '$name · $cuts $word';
  }

  static String get resumeHint => _t(
    'Per riprendere, scegli di nuovo lo stesso file.',
    'To resume, choose the same file again.',
    'Pour reprendre, choisissez à nouveau le même fichier.',
    'Para retomar, vuelve a elegir el mismo archivo.',
    'Para retomar, escolha o mesmo arquivo novamente.',
    'Zum Fortsetzen wähle dieselbe Datei erneut.',
  );
  static String get resume =>
      _t('Riprendi', 'Resume', 'Reprendre', 'Retomar', 'Retomar', 'Fortsetzen');
  static String get discard => _t(
    'Elimina',
    'Discard',
    'Supprimer',
    'Descartar',
    'Descartar',
    'Verwerfen',
  );
  static String resumeWrongFile(String name) => _t(
    'Non è lo stesso file: per riprendere scegli «$name».',
    'That\'s not the same file: to resume, choose “$name”.',
    'Ce n\'est pas le même fichier : pour reprendre, choisissez « $name ».',
    'No es el mismo archivo: para retomar, elige «$name».',
    'Não é o mesmo arquivo: para retomar, escolha “$name”.',
    'Das ist nicht dieselbe Datei: Wähle zum Fortsetzen „$name“.',
  );

  // --- impaginazione PDF ----------------------------------------------------------
  static String get layoutPdf => _t(
    'Layout PDF',
    'PDF layout',
    'Mise en page',
    'Diseño PDF',
    'Layout PDF',
    'PDF-Layout',
  );
  static String get layoutTitle => _t(
    'Scegli layout del PDF',
    'Choose PDF layout',
    'Choisir la mise en page',
    'Elige el diseño del PDF',
    'Escolha o layout do PDF',
    'PDF-Layout wählen',
  );
  static String get layoutCentered => _t(
    'Centrato',
    'Centered',
    'Centré',
    'Centrado',
    'Centralizado',
    'Zentriert',
  );
  static String get layoutTop =>
      _t('In alto', 'Top', 'En haut', 'Arriba', 'No topo', 'Oben');
  static String get layoutShrink => _t(
    'Riduci pagina',
    'Shrink page',
    'Réduire la page',
    'Reducir página',
    'Reduzir página',
    'Seite verkleinern',
  );
  static String get applyAndContinue => _t(
    'Applica e continua',
    'Apply and continue',
    'Appliquer et continuer',
    'Aplicar y continuar',
    'Aplicar e continuar',
    'Anwenden und weiter',
  );
  static String get placeContent => _t(
    'Posiziona il contenuto',
    'Position the content',
    'Placer le contenu',
    'Colocar el contenido',
    'Posicionar o conteúdo',
    'Inhalt platzieren',
  );
  static String get layoutForNext => _t(
    'Usa questo layout anche per le prossime pagine',
    'Also use this layout for the next pages',
    'Utiliser aussi cette mise en page pour les pages suivantes',
    'Usar este diseño también en las próximas páginas',
    'Usar este layout também nas próximas páginas',
    'Dieses Layout auch für die nächsten Seiten verwenden',
  );
  static String get cancel =>
      _t('Annulla', 'Cancel', 'Annuler', 'Cancelar', 'Cancelar', 'Abbrechen');
  static String get apply =>
      _t('Applica', 'Apply', 'Appliquer', 'Aplicar', 'Aplicar', 'Anwenden');
  static String get rasterNote => _t(
    'Le pagine tagliate diventano immagini: il testo non sarà più selezionabile e '
        'le firme digitali non resteranno valide. Le pagine non tagliate restano intatte.',
    'Cut pages become images: text will no longer be selectable and digital '
        'signatures will no longer be valid. Uncut pages stay intact.',
    'Les pages découpées deviennent des images : le texte ne sera plus '
        'sélectionnable et les signatures numériques ne seront plus valides. '
        'Les pages non découpées restent intactes.',
    'Las páginas recortadas se convierten en imágenes: el texto ya no se podrá '
        'seleccionar y las firmas digitales dejarán de ser válidas. Las páginas '
        'sin recortar quedan intactas.',
    'As páginas cortadas viram imagens: o texto não poderá mais ser '
        'selecionado e as assinaturas digitais deixarão de ser válidas. As '
        'páginas não cortadas ficam intactas.',
    'Geschnittene Seiten werden zu Bildern: Der Text ist nicht mehr auswählbar '
        'und digitale Signaturen sind nicht mehr gültig. Nicht geschnittene '
        'Seiten bleiben unverändert.',
  );
  static String get positionTitle => _t(
    'Personalizza posizione',
    'Custom position',
    'Position personnalisée',
    'Posición personalizada',
    'Posição personalizada',
    'Eigene Position',
  );
  static String get positionHint => _t(
    'Trascina il contenuto per scegliere dove metterlo nel foglio. La dimensione non cambia.',
    'Drag the content to choose where it goes on the page. Its size doesn\'t change.',
    'Faites glisser le contenu pour choisir où le placer sur la page. Sa taille ne change pas.',
    'Arrastra el contenido para elegir dónde colocarlo en la página. El tamaño no cambia.',
    'Arraste o conteúdo para escolher onde colocá-lo na página. O tamanho não muda.',
    'Zieh den Inhalt dorthin, wo er auf der Seite stehen soll. Die Größe ändert sich nicht.',
  );
  static String get confirmPosition => _t(
    'Conferma posizione',
    'Confirm position',
    'Confirmer la position',
    'Confirmar posición',
    'Confirmar posição',
    'Position bestätigen',
  );
  static String pageOf(int page, int total) => _t(
    'Pag. $page di $total',
    'Page $page of $total',
    'Page $page sur $total',
    'Pág. $page de $total',
    'Pág. $page de $total',
    'Seite $page von $total',
  );
  static String get previousPage => _t(
    'Pagina precedente',
    'Previous page',
    'Page précédente',
    'Página anterior',
    'Página anterior',
    'Vorherige Seite',
  );
  static String get nextPage => _t(
    'Pagina successiva',
    'Next page',
    'Page suivante',
    'Página siguiente',
    'Próxima página',
    'Nächste Seite',
  );

  // --- editor --------------------------------------------------------------------
  static String get share => _t(
    'Condividi',
    'Share',
    'Partager',
    'Compartir',
    'Compartilhar',
    'Teilen',
  );
  static String get save =>
      _t('Salva', 'Save', 'Enregistrer', 'Guardar', 'Salvar', 'Sichern');
  static const undo = 'Undo';
  static const redo = 'Redo';
  static String get fineTitle => _t(
    'Precisione al pixel',
    'Pixel precision',
    'Précision au pixel',
    'Precisión al píxel',
    'Precisão de pixel',
    'Pixelgenau',
  );
  static String get fineHint => _t(
    'Tieni premuto questo tasto per spostare le linee A e B di 1 pixel alla volta. Oppure trascinale come sempre.',
    'Press and hold this button to move lines A and B 1 pixel at a time. Or just drag them as usual.',
    'Maintiens ce bouton appuyé pour déplacer les lignes A et B d\'1 pixel à la fois. Ou fais-les glisser comme d\'habitude.',
    'Mantén pulsado este botón para mover las líneas A y B de 1 en 1 píxel. O arrástralas como siempre.',
    'Toque e segure este botão para mover as linhas A e B 1 pixel por vez. Ou arraste-as como sempre.',
    'Halte diese Taste gedrückt, um die Linien A und B pixelweise zu verschieben. Oder zieh sie wie gewohnt.',
  );
  static String get fineDone =>
      _t('Fatto', 'Done', 'OK', 'Listo', 'Pronto', 'Fertig');
  static String get removePortion => _t(
    'Rimuovi porzione',
    'Remove section',
    'Supprimer la partie',
    'Eliminar sección',
    'Remover parte',
    'Bereich entfernen',
  );
  static String get horizontal => _t(
    'Orizzontale',
    'Horizontal',
    'Horizontal',
    'Horizontal',
    'Horizontal',
    'Horizontal',
  );
  static String get vertical => _t(
    'Verticale',
    'Vertical',
    'Vertical',
    'Vertical',
    'Vertical',
    'Vertikal',
  );
  static String lineLabel(String l) =>
      _t('Linea $l', 'Line $l', 'Ligne $l', 'Línea $l', 'Linha $l', 'Linie $l');
  static const smash = 'SMASH';
  static String get smashOn => _t(
    'SMASH attivo',
    'SMASH on',
    'SMASH activé',
    'SMASH activado',
    'SMASH ativado',
    'SMASH an',
  );
  static String get smashOff => _t(
    'SMASH disattivato',
    'SMASH off',
    'SMASH désactivé',
    'SMASH desactivado',
    'SMASH desativado',
    'SMASH aus',
  );

  // --- salvataggio e condivisione -------------------------------------------------
  static String get pdfSaved => _t(
    'PDF salvato',
    'PDF saved',
    'PDF enregistré',
    'PDF guardado',
    'PDF salvo',
    'PDF gespeichert',
  );
  static String get downloaded => _t(
    'File scaricato',
    'File downloaded',
    'Fichier téléchargé',
    'Archivo descargado',
    'Arquivo baixado',
    'Datei heruntergeladen',
  );
  static String get fileReady => _t(
    'File pronto',
    'File ready',
    'Fichier prêt',
    'Archivo listo',
    'Arquivo pronto',
    'Datei bereit',
  );
  static String get saveToGalleryHint => _t(
    'Nel menu che si apre scegli «Salva immagine» per metterla in Galleria/Foto.',
    'In the menu that opens, choose “Save Image” to add it to Photos/Gallery.',
    'Dans le menu qui s\'ouvre, choisissez « Enregistrer l\'image » pour '
        'l\'ajouter à Photos/Galerie.',
    'En el menú que se abre, elige «Guardar imagen» para añadirla a Fotos/Galería.',
    'No menu que se abre, escolha “Salvar Imagem” para adicioná-la a Fotos/Galeria.',
    'Wähle im Menü, das sich öffnet, „Bild sichern“, um es in Fotos/Galerie abzulegen.',
  );
  static String get saveToFilesHint => _t(
    'Nel menu che si apre scegli «Salva su File».',
    'In the menu that opens, choose “Save to Files”.',
    'Dans le menu qui s\'ouvre, choisissez « Enregistrer dans Fichiers ».',
    'En el menú que se abre, elige «Guardar en Archivos».',
    'No menu que se abre, escolha “Salvar em Arquivos”.',
    'Wähle im Menü, das sich öffnet, „In Dateien sichern“.',
  );
  static String get saveToGallery => _t(
    'Salva in Galleria',
    'Save to Photos',
    'Enregistrer dans Photos',
    'Guardar en Fotos',
    'Salvar em Fotos',
    'In Fotos sichern',
  );
  static String get saveToFiles => _t(
    'Salva in File',
    'Save to Files',
    'Enregistrer dans Fichiers',
    'Guardar en Archivos',
    'Salvar em Arquivos',
    'In Dateien sichern',
  );
  static String get download => _t(
    'Scarica',
    'Download',
    'Télécharger',
    'Descargar',
    'Baixar',
    'Herunterladen',
  );
  static String get saved => _t(
    'Immagine salvata nelle Foto',
    'Image saved to Photos',
    'Image enregistrée dans Photos',
    'Imagen guardada en Fotos',
    'Imagem salva em Fotos',
    'Bild in Fotos gespeichert',
  );
  static String get saveDenied => _t(
    'Per salvare serve il permesso di accedere alle Foto. Puoi darlo dalle Impostazioni.',
    'Saving needs permission to access Photos. You can grant it in Settings.',
    'L\'enregistrement nécessite l\'accès à Photos. Vous pouvez l\'autoriser dans Réglages.',
    'Para guardar se necesita permiso para acceder a Fotos. Puedes darlo en Ajustes.',
    'Para salvar é preciso permissão para acessar Fotos. Você pode concedê-la em Ajustes.',
    'Zum Speichern ist Zugriff auf Fotos nötig. Du kannst ihn in den Einstellungen erlauben.',
  );
  static String get saveFailed => _t(
    'Salvataggio non riuscito. Riprova.',
    'Saving failed. Try again.',
    'L\'enregistrement a échoué. Réessayez.',
    'No se pudo guardar. Inténtalo de nuevo.',
    'Não foi possível salvar. Tente novamente.',
    'Speichern fehlgeschlagen. Versuch es noch einmal.',
  );
  static String get saveUnavailable => _t(
    'Su questo dispositivo il salvataggio nelle Foto non è disponibile: usa Condividi.',
    'Saving to Photos isn\'t available on this device: use Share.',
    'L\'enregistrement dans Photos n\'est pas disponible sur cet appareil : utilisez Partager.',
    'En este dispositivo no se puede guardar en Fotos: usa Compartir.',
    'Neste dispositivo não é possível salvar em Fotos: use Compartilhar.',
    'Auf diesem Gerät ist Speichern in Fotos nicht möglich: Nutze Teilen.',
  );
  static String get shareFailed => _t(
    'Condivisione non riuscita. Riprova.',
    'Sharing failed. Try again.',
    'Le partage a échoué. Réessayez.',
    'No se pudo compartir. Inténtalo de nuevo.',
    'Não foi possível compartilhar. Tente novamente.',
    'Teilen fehlgeschlagen. Versuch es noch einmal.',
  );
  static String get loadFailed => _t(
    'Non riesco ad aprire questa immagine. Prova con un altro file.',
    'This image can\'t be opened. Try another file.',
    'Impossible d\'ouvrir cette image. Essayez un autre fichier.',
    'No se puede abrir esta imagen. Prueba con otro archivo.',
    'Não foi possível abrir esta imagem. Tente outro arquivo.',
    'Dieses Bild lässt sich nicht öffnen. Versuch es mit einer anderen Datei.',
  );
  static String get tooLarge => _t(
    'Immagine troppo grande: il lato massimo è di 16.000 pixel.',
    'Image too large: the longest side can be at most 16,000 pixels.',
    'Image trop grande : le plus grand côté peut faire au maximum 16 000 pixels.',
    'Imagen demasiado grande: el lado mayor puede tener como máximo 16.000 píxeles.',
    'Imagem grande demais: o lado maior pode ter no máximo 16.000 pixels.',
    'Bild zu groß: Die längste Seite darf höchstens 16.000 Pixel haben.',
  );
  static String get preparing => _t(
    'Preparo il file…',
    'Preparing the file…',
    'Préparation du fichier…',
    'Preparando el archivo…',
    'Preparando o arquivo…',
    'Datei wird vorbereitet…',
  );
  static String get opening => _t(
    'Apro l\'immagine…',
    'Opening the image…',
    'Ouverture de l\'image…',
    'Abriendo la imagen…',
    'Abrindo a imagem…',
    'Bild wird geöffnet…',
  );

  // --- più immagini ---------------------------------------------------------

  static String get shareAsTitle => _t(
    'Come vuoi condividerlo?',
    'How do you want to share it?',
    'Comment le partager ?',
    '¿Cómo quieres compartirlo?',
    'Como você quer compartilhar?',
    'Wie möchtest du teilen?',
  );
  static String get saveAsTitle => _t(
    'Come vuoi salvarlo?',
    'How do you want to save it?',
    'Comment l\'enregistrer ?',
    '¿Cómo quieres guardarlo?',
    'Como você quer salvar?',
    'Wie möchtest du speichern?',
  );
  static String saveAsImage(String fmt) => _t(
    'Immagine ($fmt)',
    'Image ($fmt)',
    'Image ($fmt)',
    'Imagen ($fmt)',
    'Imagem ($fmt)',
    'Bild ($fmt)',
  );
  static String saveAsImages(int n) => _t(
    '$n immagini separate',
    '$n separate images',
    '$n images séparées',
    '$n imágenes separadas',
    '$n imagens separadas',
    '$n einzelne Bilder',
  );
  static String get saveAsPdf => 'PDF';
  static String saveAsPdfPages(int n) => _t(
    'PDF unico ($n pagine)',
    'Single PDF ($n pages)',
    'PDF unique ($n pages)',
    'PDF único ($n páginas)',
    'PDF único ($n páginas)',
    'Ein PDF ($n Seiten)',
  );
  static String savedMany(int n) => _t(
    '$n immagini salvate nelle Foto',
    '$n images saved to Photos',
    '$n images enregistrées dans Photos',
    '$n imágenes guardadas en Fotos',
    '$n imagens salvas em Fotos',
    '$n Bilder in Fotos gespeichert',
  );
  static String onlyFirstImages(int n) => _t(
    'Puoi aprire fino a $n immagini: ho preso le prime $n.',
    'You can open up to $n images: the first $n were taken.',
    'Vous pouvez ouvrir jusqu\'à $n images : les $n premières ont été prises.',
    'Puedes abrir hasta $n imágenes: se han tomado las $n primeras.',
    'Você pode abrir até $n imagens: foram usadas as $n primeiras.',
    'Du kannst bis zu $n Bilder öffnen: die ersten $n wurden übernommen.',
  );
  static String get largeImagesTitle => _t(
    'Immagini molto pesanti',
    'Very large images',
    'Images très lourdes',
    'Imágenes muy pesadas',
    'Imagens muito pesadas',
    'Sehr große Bilder',
  );
  static String largeImagesBody(int mb) => _t(
    'Queste immagini pesano $mb MB in tutto. Nel browser del telefono la '
        'pagina potrebbe chiudersi per mancanza di memoria: per sicurezza usa '
        'l\'app oppure scegline meno.',
    'These images are $mb MB in total. The phone\'s browser may close the '
        'page for lack of memory: to be safe, use the app or pick fewer.',
    'Ces images pèsent $mb Mo au total. Le navigateur du téléphone pourrait '
        'fermer la page par manque de mémoire : par sécurité, utilisez l\'app '
        'ou choisissez-en moins.',
    'Estas imágenes pesan $mb MB en total. El navegador del teléfono podría '
        'cerrar la página por falta de memoria: por seguridad, usa la app o '
        'elige menos.',
    'Estas imagens pesam $mb MB no total. O navegador do celular pode fechar '
        'a página por falta de memória: por segurança, use o app ou escolha '
        'menos.',
    'Diese Bilder sind insgesamt $mb MB groß. Der Browser des Handys könnte '
        'die Seite wegen Speichermangel schließen: nutze sicherheitshalber die '
        'App oder wähle weniger aus.',
  );

  static String get addImages =>
      _t('Aggiungi', 'Add', 'Ajouter', 'Añadir', 'Adicionar', 'Hinzufügen');
  static String get addImagesLabel => _t(
    'Aggiungi immagini in fondo',
    'Add images at the end',
    'Ajouter des images à la fin',
    'Añadir imágenes al final',
    'Adicionar imagens no final',
    'Bilder am Ende hinzufügen',
  );
  static String get removePage => _t(
    'Togli questa pagina',
    'Remove this page',
    'Retirer cette page',
    'Quitar esta página',
    'Remover esta página',
    'Diese Seite entfernen',
  );
  static String get removePageTitle => _t(
    'Togliere questa pagina?',
    'Remove this page?',
    'Retirer cette page ?',
    '¿Quitar esta página?',
    'Remover esta página?',
    'Diese Seite entfernen?',
  );
  static String get wholePageTitle => _t(
    'Stai togliendo tutta la pagina. Vuoi eliminarla?',
    'You are removing the whole page. Delete it?',
    'Vous retirez toute la page. La supprimer ?',
    'Estás quitando toda la página. ¿Eliminarla?',
    'Você está removendo a página inteira. Excluí-la?',
    'Du entfernst die ganze Seite. Löschen?',
  );
  static String get cannotRemoveAll => _t(
    'Non puoi togliere tutto: il foglio resterebbe vuoto.',
    'You can\'t remove everything: the page would be empty.',
    'Impossible de tout retirer : la page serait vide.',
    'No puedes quitarlo todo: la hoja quedaría vacía.',
    'Você não pode remover tudo: a folha ficaria vazia.',
    'Du kannst nicht alles entfernen: die Seite wäre leer.',
  );
  static String get zoom => _t('Zoom', 'Zoom', 'Zoom', 'Zoom', 'Zoom', 'Zoom');
  static String get removePageBody => _t(
    'L\'immagine e i suoi tagli escono dal documento. La foto originale non '
        'viene toccata.',
    'The image and its cuts leave the document. The original photo is not '
        'touched.',
    'L\'image et ses découpes sortent du document. La photo d\'origine '
        'n\'est pas modifiée.',
    'La imagen y sus cortes salen del documento. La foto original no se '
        'modifica.',
    'A imagem e seus cortes saem do documento. A foto original não é '
        'alterada.',
    'Das Bild und seine Schnitte werden aus dem Dokument entfernt. Das '
        'Originalfoto bleibt unverändert.',
  );
  static String get remove =>
      _t('Togli', 'Remove', 'Retirer', 'Quitar', 'Remover', 'Entfernen');
  static String imagesLimit(int n) => _t(
    'Hai già $n immagini: è il massimo.',
    'You already have $n images: that\'s the maximum.',
    'Vous avez déjà $n images : c\'est le maximum.',
    'Ya tienes $n imágenes: es el máximo.',
    'Você já tem $n imagens: é o máximo.',
    'Du hast bereits $n Bilder: das ist das Maximum.',
  );
  static String get removePdfPageBody => _t(
    'La pagina e i suoi tagli escono dal documento che salverai. Il PDF '
        'originale non viene toccato.',
    'The page and its cuts leave the document you will save. The original '
        'PDF is not touched.',
    'La page et ses découpes sortent du document que vous enregistrerez. Le '
        'PDF d\'origine n\'est pas modifié.',
    'La página y sus cortes salen del documento que guardarás. El PDF '
        'original no se modifica.',
    'A página e seus cortes saem do documento que você vai salvar. O PDF '
        'original não é alterado.',
    'Die Seite und ihre Schnitte werden aus dem Dokument entfernt, das du '
        'speicherst. Das Original-PDF bleibt unverändert.',
  );
  static String get movePageBack => _t(
    'Sposta indietro',
    'Move back',
    'Déplacer avant',
    'Mover atrás',
    'Mover para trás',
    'Nach vorne verschieben',
  );
  static String get movePageForward => _t(
    'Sposta avanti',
    'Move forward',
    'Déplacer après',
    'Mover adelante',
    'Mover para frente',
    'Nach hinten verschieben',
  );
  static String get pageOptions => _t(
    'Opzioni pagina',
    'Page options',
    'Options de la page',
    'Opciones de página',
    'Opções da página',
    'Seitenoptionen',
  );

  // --- menu ---------------------------------------------------------------

  static String get menu => 'Menu';
  static String get shareApp => _t(
    'Condividi l\'app',
    'Share the app',
    'Partager l\'app',
    'Compartir la app',
    'Compartilhar o app',
    'App teilen',
  );
  static String shareAppText(String url) => _t(
    'Prova SmashCrop: togli da foto e PDF le parti che non servono, con un pugno di SMASH! $url',
    'Try SmashCrop: remove the parts you don\'t need from photos and PDFs with one punch from SMASH! $url',
    'Essaie SmashCrop : retire des photos et des PDF les parties inutiles, d\'un coup de poing de SMASH ! $url',
    'Prueba SmashCrop: quita de fotos y PDF lo que no sirve, ¡con un puñetazo de SMASH! $url',
    'Experimente o SmashCrop: tire de fotos e PDFs o que não serve, com um soco do SMASH! $url',
    'Probier SmashCrop: Entferne Überflüssiges aus Fotos und PDFs – mit einem Schlag von SMASH! $url',
  );
  static String get privacy => _t(
    'Privacy',
    'Privacy',
    'Confidentialité',
    'Privacidad',
    'Privacidade',
    'Datenschutz',
  );
  static String get privacyBody => _t(
    'SmashCrop lavora sul tuo dispositivo: foto e PDF non vengono caricati su nessun server e non '
        'li vediamo. Non usiamo account. Per capire quali pubblicità funzionano, l\'app manda a Meta, '
        'TikTok, Google e Apple solo eventi d\'uso (per esempio «primo taglio»), mai i tuoi file; su '
        'iPhone l\'identificativo pubblicitario si usa solo se lo permetti. Sul dispositivo restano le tue '
        'preferenze e il lavoro in corso (i tagli e una copia del file, che si cancella quando chiudi il '
        'lavoro). I file salvati non contengono posizione GPS né altri dati della foto originale.',
    'SmashCrop works on your device: photos and PDFs are not uploaded to any server and we never '
        'see them. We use no accounts. To learn which ads work, the app sends Meta, TikTok, Google and '
        'Apple only usage events (for example "first cut"), never your files; on iPhone the advertising '
        'identifier is used only if you allow it. Your preferences and the work in progress (the cuts and '
        'a copy of the file, deleted when you close the work) stay on the device. Saved files contain no '
        'GPS location or other data from the original photo.',
    'SmashCrop fonctionne sur votre appareil : les photos et PDF ne sont envoyés sur aucun serveur '
        'et nous ne les voyons pas. Nous n\'utilisons pas de compte. Pour savoir quelles publicités '
        'fonctionnent, l\'app envoie à Meta, TikTok, Google et Apple uniquement des événements '
        'd\'utilisation (par exemple « première découpe »), jamais vos fichiers ; sur iPhone, '
        'l\'identifiant publicitaire n\'est utilisé que si vous l\'autorisez. Vos préférences et le '
        'travail en cours (les découpes et une copie du fichier, supprimée quand vous fermez le travail) '
        'restent sur l\'appareil. Les fichiers enregistrés ne contiennent ni position GPS ni autres '
        'données de la photo d\'origine.',
    'SmashCrop funciona en tu dispositivo: las fotos y los PDF no se suben a ningún servidor y no '
        'los vemos. No usamos cuentas. Para saber qué anuncios funcionan, la app envía a Meta, TikTok, '
        'Google y Apple solo eventos de uso (por ejemplo «primer corte»), nunca tus archivos; en iPhone '
        'el identificador publicitario solo se usa si lo permites. Tus preferencias y el trabajo en curso '
        '(los cortes y una copia del archivo, que se borra al cerrar el trabajo) quedan en el dispositivo. '
        'Los archivos guardados no contienen la ubicación GPS ni otros datos de la foto original.',
    'O SmashCrop funciona no seu dispositivo: fotos e PDFs não são enviados para nenhum servidor e '
        'nós não os vemos. Não usamos contas. Para saber quais anúncios funcionam, o app envia à Meta, '
        'TikTok, Google e Apple apenas eventos de uso (por exemplo "primeiro corte"), nunca seus '
        'arquivos; no iPhone o identificador de publicidade só é usado se você permitir. Suas '
        'preferências e o trabalho em andamento (os cortes e uma cópia do arquivo, apagada quando você '
        'fecha o trabalho) ficam no dispositivo. Os arquivos salvos não contêm localização GPS nem outros '
        'dados da foto original.',
    'SmashCrop arbeitet auf deinem Gerät: Fotos und PDFs werden auf keinen Server hochgeladen und '
        'wir sehen sie nie. Wir nutzen keine Konten. Um zu erfahren, welche Werbung funktioniert, sendet '
        'die App an Meta, TikTok, Google und Apple nur Nutzungsereignisse (zum Beispiel „erster Schnitt"), '
        'nie deine Dateien; auf dem iPhone wird die Werbe-ID nur verwendet, wenn du es erlaubst. Deine '
        'Einstellungen und die laufende Arbeit (die Schnitte und eine Kopie der Datei, die beim Schließen '
        'der Arbeit gelöscht wird) bleiben auf dem Gerät. Gespeicherte Dateien enthalten keinen '
        'GPS-Standort und keine anderen Daten des Originalfotos.',
  );
  static String get close =>
      _t('Chiudi', 'Close', 'Fermer', 'Cerrar', 'Fechar', 'Schließen');
  static String get version =>
      _t('Versione', 'Version', 'Version', 'Versión', 'Versão', 'Version');

  // --- macerie ------------------------------------------------------------

  static String get fillWheelbarrow => _t(
    'Riempi una carriola',
    'Fill a wheelbarrow',
    'Remplis une brouette',
    'Llena una carretilla',
    'Enche um carrinho de mão',
    'Füll eine Schubkarre',
  );
  static String get fillMixer => _t(
    'Riempi una betoniera',
    'Fill a cement mixer',
    'Remplis une bétonnière',
    'Llena una hormigonera',
    'Enche uma betoneira',
    'Füll einen Betonmischer',
  );
  static String get fillSkip => _t(
    'Riempi un cassone',
    'Fill a skip',
    'Remplis une benne',
    'Llena un contenedor',
    'Enche uma caçamba',
    'Füll eine Mulde',
  );
  static String get fillTruck => _t(
    'Riempi un camioncino',
    'Fill a dump truck',
    'Remplis un camion-benne',
    'Llena un camión volquete',
    'Enche um caminhão basculante',
    'Füll einen Kipper',
  );
  static String get filledWheelbarrow => _t(
    'Hai riempito una carriola',
    'You filled a wheelbarrow',
    'Tu as rempli une brouette',
    'Has llenado una carretilla',
    'Você encheu um carrinho de mão',
    'Du hast eine Schubkarre gefüllt',
  );
  static String get filledMixer => _t(
    'Hai riempito una betoniera',
    'You filled a cement mixer',
    'Tu as rempli une bétonnière',
    'Has llenado una hormigonera',
    'Você encheu uma betoneira',
    'Du hast einen Betonmischer gefüllt',
  );
  static String get filledSkip => _t(
    'Hai riempito un cassone',
    'You filled a skip',
    'Tu as rempli une benne',
    'Has llenado un contenedor',
    'Você encheu uma caçamba',
    'Du hast eine Mulde gefüllt',
  );
  static String get filledTruck => _t(
    'Hai riempito un camioncino',
    'You filled a dump truck',
    'Tu as rempli un camion-benne',
    'Has llenado un camión volquete',
    'Você encheu um caminhão basculante',
    'Du hast einen Kipper gefüllt',
  );
  static String get starter => _t(
    'Il primo SMASH',
    'The first SMASH',
    'Le premier SMASH',
    'El primer SMASH',
    'O primeiro SMASH',
    'Der erste SMASH',
  );
  static String get lifetimeName => _t(
    'SmashCrop a vita',
    'SmashCrop for life',
    'SmashCrop à vie',
    'SmashCrop para siempre',
    'SmashCrop vitalício',
    'SmashCrop für immer',
  );
  static String get collection => _t(
    'Collezione',
    'Collection',
    'Collection',
    'Colección',
    'Coleção',
    'Sammlung',
  );
  static String get inUse =>
      _t('In uso', 'In use', 'Utilisé', 'En uso', 'Em uso', 'Aktiv');
  static String get useSkin => _t(
    'Usa questo SMASH',
    'Use this SMASH',
    'Utiliser ce SMASH',
    'Usar este SMASH',
    'Usar este SMASH',
    'Diesen SMASH nutzen',
  );
  static String get newBadge =>
      _t('Nuova', 'New', 'Nouveau', 'Nuevo', 'Novo', 'Neu');
  static String get lifetimeChip => _t(
    'A vita',
    'For life',
    'À vie',
    'Para siempre',
    'Vitalício',
    'Für immer',
  );
  static String get lifetimeNoAds => _t(
    'Niente pubblicità, per sempre',
    'No ads, forever',
    'Zéro pub, pour toujours',
    'Sin anuncios, para siempre',
    'Sem anúncios, para sempre',
    'Keine Werbung, für immer',
  );
  static String get lifetimeTycoon => _t(
    'Sblocchi SMASH Tycoon e il suo balletto',
    'Unlock SMASH Tycoon and his dance',
    'Débloque SMASH Tycoon et sa danse',
    'Desbloquea a SMASH Tycoon y su baile',
    'Desbloqueie o SMASH Tycoon e a dança dele',
    'Schalte SMASH Tycoon und seinen Tanz frei',
  );
  static String get lifetimeOnce => _t(
    'Paghi una volta sola. Niente abbonamento.',
    'Pay once. No subscription.',
    'Tu paies une seule fois. Pas d\'abonnement.',
    'Pagas una sola vez. Sin suscripción.',
    'Você paga uma vez só. Sem assinatura.',
    'Einmal zahlen. Kein Abo.',
  );
  static String get buy =>
      _t('Compra', 'Buy', 'Acheter', 'Comprar', 'Comprar', 'Kaufen');
  static String buyFor(String price) => _t(
    'Compra a $price',
    'Buy for $price',
    'Acheter pour $price',
    'Comprar por $price',
    'Comprar por $price',
    'Kaufen für $price',
  );
  static String get lifetimeOwned => _t(
    'È tuo per sempre. Grazie!',
    'It\'s yours forever. Thank you!',
    'Il est à toi pour toujours. Merci !',
    'Es tuyo para siempre. ¡Gracias!',
    'É seu para sempre. Obrigado!',
    'Gehört dir für immer. Danke!',
  );
  static String get lifetimeThanks => _t(
    'Grazie! Niente più pubblicità e SMASH Tycoon è tuo.',
    'Thank you! No more ads, and SMASH Tycoon is yours.',
    'Merci ! Plus de pub, et SMASH Tycoon est à toi.',
    '¡Gracias! Se acabaron los anuncios y SMASH Tycoon es tuyo.',
    'Obrigado! Sem anúncios e o SMASH Tycoon é seu.',
    'Danke! Keine Werbung mehr, und SMASH Tycoon gehört dir.',
  );
  static String get purchaseRestored => _t(
    'Acquisto ripristinato.',
    'Purchase restored.',
    'Achat restauré.',
    'Compra restaurada.',
    'Compra restaurada.',
    'Kauf wiederhergestellt.',
  );
  static String get nothingToRestore => _t(
    'Nessun acquisto da ripristinare su questo account.',
    'No purchases to restore on this account.',
    'Aucun achat à restaurer sur ce compte.',
    'No hay compras que restaurar en esta cuenta.',
    'Nenhuma compra para restaurar nesta conta.',
    'Keine Käufe zum Wiederherstellen in diesem Konto.',
  );
  static String get purchaseError => _t(
    'Acquisto non riuscito. Riprova tra poco.',
    'Purchase failed. Please try again shortly.',
    'L\'achat a échoué. Réessaie dans un instant.',
    'La compra no se completó. Inténtalo de nuevo en un momento.',
    'A compra não foi concluída. Tente de novo daqui a pouco.',
    'Kauf fehlgeschlagen. Versuch es gleich noch einmal.',
  );
  static String get buyOnlyInApp => _t(
    'L\'acquisto si fa dall\'app scaricata da App Store o Google Play.',
    'You can buy it in the app from the App Store or Google Play.',
    'L\'achat se fait dans l\'app téléchargée sur l\'App Store ou Google Play.',
    'La compra se hace desde la app descargada de App Store o Google Play.',
    'A compra é feita no app baixado da App Store ou do Google Play.',
    'Kaufen kannst du in der App aus dem App Store oder Google Play.',
  );
  static String get lifetimeOfferIntro => _t(
    'Ti è servita? Tienila per sempre.',
    'Did it help? Keep it forever.',
    'Ça t\'a servi ? Garde-la pour toujours.',
    '¿Te ha servido? Quédatela para siempre.',
    'Foi útil? Fique com ele para sempre.',
    'Hat es geholfen? Behalte es für immer.',
  );
  static String get unlockWithLifetime => _t(
    'Sblocca con SmashCrop a vita',
    'Unlock with SmashCrop for life',
    'Débloquer avec SmashCrop à vie',
    'Desbloquear con SmashCrop para siempre',
    'Desbloquear com SmashCrop vitalício',
    'Mit SmashCrop für immer freischalten',
  );
  static String get notNow => _t(
    'Non ora',
    'Not now',
    'Pas maintenant',
    'Ahora no',
    'Agora não',
    'Nicht jetzt',
  );
  static String get paste =>
      _t('Incolla', 'Paste', 'Coller', 'Pegar', 'Colar', 'Einfügen');
  static String get notifications => _t(
    'Notifiche',
    'Notifications',
    'Notifications',
    'Notificaciones',
    'Notificações',
    'Benachrichtigungen',
  );
  static String get notifChannel => _t(
    'Promemoria di SMASH',
    'SMASH reminders',
    'Rappels de SMASH',
    'Recordatorios de SMASH',
    'Lembretes do SMASH',
    'SMASH-Erinnerungen',
  );
  static String get notifHungryTitle => _t(
    'SMASH ha fame 🍽️',
    'SMASH is hungry 🍽️',
    'SMASH a faim 🍽️',
    'SMASH tiene hambre 🍽️',
    'O SMASH está com fome 🍽️',
    'SMASH hat Hunger 🍽️',
  );
  static String notifHungryNext(String kg, String name) => _t(
    'Ti mancano $kg kg per sbloccare $name. Qualcosa da demolire?',
    'Only $kg kg to unlock $name. Got something to smash?',
    'Plus que $kg kg pour débloquer $name. Quelque chose à démolir ?',
    'Te faltan $kg kg para desbloquear a $name. ¿Algo que demoler?',
    'Faltam $kg kg para desbloquear o $name. Algo para demolir?',
    'Nur noch $kg kg bis $name. Hast du was zum Zerschmettern?',
  );
  static String get notifHungryBody => _t(
    'Screenshot o PDF da sistemare? È pronto a demolire.',
    'Screenshots or PDFs to fix? He\'s ready to demolish.',
    'Des captures ou des PDF à arranger ? Il est prêt à démolir.',
    '¿Capturas o PDF que arreglar? Está listo para demoler.',
    'Capturas ou PDFs para arrumar? Ele está pronto para demolir.',
    'Screenshots oder PDFs zum Aufräumen? Er ist bereit.',
  );
  static String get notifPunchTitle => _t(
    'Un pugno e via 👊',
    'One punch and done 👊',
    'Un coup de poing et c\'est fait 👊',
    'Un puñetazo y listo 👊',
    'Um soco e pronto 👊',
    'Ein Schlag und fertig 👊',
  );
  static String get notifPunchBody => _t(
    'Screenshot troppo lunghi, PDF con pagine di troppo? SMASH li sistema in un secondo.',
    'Screenshots too long, PDFs with extra pages? SMASH fixes them in a second.',
    'Captures trop longues, PDF avec des pages en trop ? SMASH les règle en une seconde.',
    '¿Capturas demasiado largas, PDF con páginas de más? SMASH los arregla en un segundo.',
    'Capturas longas demais, PDFs com páginas sobrando? O SMASH resolve num segundo.',
    'Zu lange Screenshots, PDFs mit überflüssigen Seiten? SMASH erledigt das in einer Sekunde.',
  );
  static String get notifBoredTitle => _t(
    'SMASH si annoia… 😴',
    'SMASH is bored… 😴',
    'SMASH s\'ennuie… 😴',
    'SMASH se aburre… 😴',
    'O SMASH está entediado… 😴',
    'SMASH langweilt sich… 😴',
  );
  static String get notifBoredBody => _t(
    'Le macerie non si mangiano da sole. Torna a fargli fare un po\' di danni.',
    'Rubble doesn\'t eat itself. Come back and let him wreck something.',
    'Les gravats ne se mangent pas tout seuls. Reviens lui faire casser quelque chose.',
    'Los escombros no se comen solos. Vuelve y déjale destrozar algo.',
    'O entulho não se come sozinho. Volte e deixe ele destruir alguma coisa.',
    'Schutt frisst sich nicht von selbst. Komm zurück und lass ihn was zerlegen.',
  );
  static String get writeUs => _t(
    'Scrivici',
    'Contact us',
    'Nous écrire',
    'Escríbenos',
    'Fale conosco',
    'Schreib uns',
  );
  static String get rateApp => _t(
    'Valuta SmashCrop',
    'Rate SmashCrop',
    'Noter SmashCrop',
    'Valorar SmashCrop',
    'Avaliar o SmashCrop',
    'SmashCrop bewerten',
  );

  static String get lockedLifetime => _t(
    'Con SmashCrop a vita',
    'With SmashCrop for life',
    'Avec SmashCrop à vie',
    'Con SmashCrop para siempre',
    'Com SmashCrop vitalício',
    'Mit SmashCrop für immer',
  );

  /// Dopo aver scelto un personaggio nella Collezione.
  static String nowUsing(String name) => _t(
    '$name in uso',
    '$name selected',
    '$name sélectionné',
    '$name seleccionado',
    '$name selecionado',
    '$name ausgewählt',
  );
  static String get evolvedTitle => _t(
    'SMASH si è evoluto!',
    'SMASH has evolved!',
    'SMASH a évolué !',
    '¡SMASH ha evolucionado!',
    'O SMASH evoluiu!',
    'SMASH hat sich entwickelt!',
  );
  static String get newSkinToast => _t(
    'Nuovo SMASH sbloccato!',
    'New SMASH unlocked!',
    'Nouveau SMASH débloqué !',
    '¡Nuevo SMASH desbloqueado!',
    'Novo SMASH desbloqueado!',
    'Neuer SMASH freigeschaltet!',
  );
  static String get see => _t('Vedi', 'See', 'Voir', 'Ver', 'Ver', 'Ansehen');
  static String get bucketFilled => _t(
    'Hai riempito un secchio!',
    'You filled a bucket!',
    'Tu as rempli un seau !',
    '¡Has llenado un cubo!',
    'Você encheu um balde!',
    'Du hast einen Eimer gefüllt!',
  );
  static String get activateSmash => _t(
    'Attiva SMASH',
    'Turn on SMASH',
    'Active SMASH',
    'Activa SMASH',
    'Ative o SMASH',
    'SMASH einschalten',
  );
  static String get smashSleeps => _t(
    'SMASH dorme: niente macerie',
    'SMASH is asleep: no rubble',
    'SMASH dort : pas de gravats',
    'SMASH duerme: no hay escombros',
    'SMASH está dormindo: sem entulho',
    'SMASH schläft: kein Schutt',
  );
  static String get tapForCollection => _t(
    'Tocca per la tua collezione',
    'Tap for your collection',
    'Touche pour ta collection',
    'Toca para ver tu colección',
    'Toque para ver sua coleção',
    'Tippe für deine Sammlung',
  );
  static String get sounds =>
      _t('Suoni', 'Sounds', 'Sons', 'Sonidos', 'Sons', 'Töne');
  static String get vibration => _t(
    'Vibrazione',
    'Vibration',
    'Vibration',
    'Vibración',
    'Vibração',
    'Vibration',
  );
  static String get premium =>
      _t('Premium', 'Premium', 'Premium', 'Premium', 'Premium', 'Premium');
  static String get restorePurchases => _t(
    'Ripristina acquisti',
    'Restore purchases',
    'Restaurer les achats',
    'Restaurar compras',
    'Restaurar compras',
    'Käufe wiederherstellen',
  );
  static String get comingSoon => _t(
    'Disponibile presto.',
    'Coming soon.',
    'Bientôt disponible.',
    'Disponible pronto.',
    'Disponível em breve.',
    'Bald verfügbar.',
  );
  static String get yourCounter => _t(
    'Il tuo contatore',
    'Your counter',
    'Ton compteur',
    'Tu contador',
    'Seu contador',
    'Dein Zähler',
  );
  static String get saveProgress => _t(
    'Salva i miei progressi',
    'Save my progress',
    'Sauvegarder ma progression',
    'Guardar mi progreso',
    'Salvar meu progresso',
    'Fortschritt sichern',
  );
  static String get haveCode => _t(
    'Ho un codice',
    'I have a code',
    "J'ai un code",
    'Tengo un código',
    'Tenho um código',
    'Ich habe einen Code',
  );
  static String get recoveryBody => _t(
    'Conserva questo codice (per esempio con uno screenshot). Su un altro telefono o nella webapp, scegli "Ho un codice" e ritrovi le tue macerie e i tuoi SMASH.',
    'Keep this code (for example with a screenshot). On another phone or in the web app, choose "I have a code" to get back your rubble and your SMASHes.',
    "Garde ce code (par exemple avec une capture d'écran). Sur un autre téléphone ou dans l'app web, choisis « J'ai un code » pour retrouver tes gravats et tes SMASH.",
    'Guarda este código (por ejemplo con una captura). En otro teléfono o en la web app, elige "Tengo un código" y recuperas tus escombros y tus SMASH.',
    'Guarde este código (por exemplo com uma captura de tela). Em outro celular ou no app web, escolha "Tenho um código" e recupere seu entulho e seus SMASH.',
    'Bewahre diesen Code auf (zum Beispiel per Screenshot). Auf einem anderen Handy oder in der Web-App wählst du „Ich habe einen Code" und bekommst Schutt und SMASHs zurück.',
  );
  static String get copy =>
      _t('Copia', 'Copy', 'Copier', 'Copiar', 'Copiar', 'Kopieren');
  static String get copied => _t(
    'Codice copiato',
    'Code copied',
    'Code copié',
    'Código copiado',
    'Código copiado',
    'Code kopiert',
  );
  static String get enterCode => _t(
    'Scrivi il tuo codice',
    'Type your code',
    'Saisis ton code',
    'Escribe tu código',
    'Digite seu código',
    'Gib deinen Code ein',
  );
  static String get codeInvalid => _t(
    'Codice non valido. Controlla le lettere e riprova.',
    'Invalid code. Check the letters and try again.',
    'Code non valide. Vérifie les lettres et réessaie.',
    'Código no válido. Revisa las letras y vuelve a intentarlo.',
    'Código inválido. Confira as letras e tente de novo.',
    'Ungültiger Code. Prüfe die Buchstaben und versuche es erneut.',
  );
  static String get codeApplied => _t(
    'Progressi recuperati!',
    'Progress restored!',
    'Progression récupérée !',
    '¡Progreso recuperado!',
    'Progresso recuperado!',
    'Fortschritt wiederhergestellt!',
  );
  static String get restoreCode => _t(
    'Recupera',
    'Restore',
    'Récupérer',
    'Recuperar',
    'Recuperar',
    'Wiederherstellen',
  );
  static String get help =>
      _t('Aiuto', 'Help', 'Aide', 'Ayuda', 'Ajuda', 'Hilfe');
  static String get howItWorks => _t(
    'Come funziona',
    'How it works',
    'Comment ça marche',
    'Cómo funciona',
    'Como funciona',
    'So funktioniert es',
  );
  static String get howItWorksBody => _t(
    'Uno screenshot infinito, una foto, un PDF con dentro un pezzo che non deve esserci. Fino a oggi c\'erano solo due strade, tutte e due pessime: ritagliare a pezzi e riattaccare tutto a mano, oppure affidarsi a un\'IA che inventa, deforma e sbaglia.\n\nSmashCrop apre la terza, quella a cui nessuno aveva mai pensato. Segni la fascia con A e B, in orizzontale o in verticale. Un tocco su "Rimuovi porzione". Fatto. Il pezzo sparisce e il resto si richiude da solo, senza toccare nient\'altro. Anche su PDF di decine di pagine. Secondi, non minuti.\n\nE a sferrare il colpo è lui: SMASH. Il robot che non ritaglia, DEMOLISCE. Ogni porzione che elimini la polverizza con un pugno e la divora come maceria. Più distruggi, più diventa forte: riempi carriola, betoniera, cassone e camioncino e si evolve in nuovi SMASH, uno più devastante dell\'altro. Tu sistemi i tuoi file in un lampo, lui entra nella leggenda.\n\n(Con SMASH spento il taglio funziona uguale, ma le macerie non si contano.)',
    'An endless screenshot, a photo, a PDF with a piece that shouldn\'t be there. Until now there were only two ways, both terrible: cut it into pieces and stitch everything back by hand, or trust an AI that makes things up, warps and gets it wrong.\n\nSmashCrop opens the third way, the one nobody had ever thought of. Mark the strip with A and B, horizontally or vertically. One tap on "Remove section". Done. The piece vanishes and the rest closes up by itself, without touching anything else. Even on PDFs dozens of pages long. Seconds, not minutes.\n\nAnd the one who lands the blow is him: SMASH. The robot that doesn\'t crop, he DEMOLISHES. Every section you delete, he pulverizes with one punch and devours as rubble. The more you destroy, the stronger he gets: fill the wheelbarrow, mixer, skip and truck and he evolves into new SMASHes, each one more devastating than the last. You fix your files in a flash, he becomes a legend.\n\n(With SMASH off, cutting works just the same, but rubble isn\'t counted.)',
    'Une capture d\'écran interminable, une photo, un PDF avec un morceau qui n\'a rien à faire là. Jusqu\'ici, il n\'y avait que deux solutions, toutes les deux pénibles : découper en morceaux et tout recoller à la main, ou faire confiance à une IA qui invente, déforme et se trompe.\n\nSmashCrop ouvre la troisième, celle à laquelle personne n\'avait jamais pensé. Marque la bande avec A et B, à l\'horizontale ou à la verticale. Un tap sur « Supprimer la partie ». Terminé. Le morceau disparaît et le reste se referme tout seul, sans rien toucher d\'autre. Même sur des PDF de dizaines de pages. Des secondes, pas des minutes.\n\nEt celui qui porte le coup, c\'est lui : SMASH. Le robot qui ne recadre pas, il DÉMOLIT. Chaque partie que tu supprimes, il la pulvérise d\'un coup de poing et la dévore comme des gravats. Plus tu détruis, plus il devient fort : remplis brouette, bétonnière, benne et camion, et il évolue en nouveaux SMASH, tous plus dévastateurs les uns que les autres. Toi, tu règles tes fichiers en un éclair ; lui entre dans la légende.\n\n(SMASH éteint, la coupe fonctionne pareil, mais les gravats ne comptent pas.)',
    'Una captura infinita, una foto, un PDF con un trozo que no debería estar ahí. Hasta hoy solo había dos caminos, los dos pésimos: recortar a trozos y volver a pegarlo todo a mano, o fiarse de una IA que se inventa cosas, deforma y se equivoca.\n\nSmashCrop abre el tercero, el que a nadie se le había ocurrido. Marca la franja con A y B, en horizontal o en vertical. Un toque en "Eliminar sección". Listo. El trozo desaparece y el resto se cierra solo, sin tocar nada más. Incluso en PDF de decenas de páginas. Segundos, no minutos.\n\nY quien da el golpe es él: SMASH. El robot que no recorta, DEMUELE. Cada sección que eliminas la pulveriza de un puñetazo y la devora como escombros. Cuanto más destruyes, más fuerte se hace: llena carretilla, hormigonera, contenedor y camión y evoluciona en nuevos SMASH, cada uno más devastador que el anterior. Tú arreglas tus archivos en un instante; él se convierte en leyenda.\n\n(Con SMASH apagado el corte funciona igual, pero los escombros no cuentan.)',
    'Uma captura de tela sem fim, uma foto, um PDF com um pedaço que não devia estar ali. Até hoje só havia dois caminhos, os dois péssimos: recortar em pedaços e colar tudo de volta à mão, ou confiar numa IA que inventa, deforma e erra.\n\nO SmashCrop abre o terceiro, aquele em que ninguém nunca tinha pensado. Marque a faixa com A e B, na horizontal ou na vertical. Um toque em "Remover parte". Pronto. O pedaço some e o resto se fecha sozinho, sem mexer em mais nada. Até em PDFs de dezenas de páginas. Segundos, não minutos.\n\nE quem dá o golpe é ele: o SMASH. O robô que não recorta, DEMOLE. Cada parte que você elimina, ele pulveriza com um soco e devora como entulho. Quanto mais você destrói, mais forte ele fica: encha carrinho, betoneira, caçamba e caminhão e ele evolui para novos SMASH, um mais devastador que o outro. Você resolve seus arquivos num piscar de olhos; ele vira lenda.\n\n(Com o SMASH desligado o corte funciona igual, mas o entulho não conta.)',
    'Ein endloser Screenshot, ein Foto, ein PDF mit einem Stück, das da nicht hingehört. Bisher gab es nur zwei Wege, beide mies: in Teile schneiden und alles von Hand wieder zusammensetzen oder einer KI vertrauen, die etwas erfindet, verzerrt und danebenliegt.\n\nSmashCrop eröffnet den dritten, an den noch nie jemand gedacht hat. Markiere den Streifen mit A und B, waagerecht oder senkrecht. Ein Tipp auf „Bereich entfernen". Fertig. Das Stück verschwindet und der Rest schließt sich von selbst, ohne dass sonst etwas angetastet wird. Sogar bei PDFs mit Dutzenden Seiten. Sekunden, nicht Minuten.\n\nUnd den Schlag führt er aus: SMASH. Der Roboter, der nicht zuschneidet, sondern ZERSCHMETTERT. Jeden Bereich, den du löschst, pulverisiert er mit einem Faustschlag und verschlingt ihn als Schutt. Je mehr du zerstörst, desto stärker wird er: Füll Schubkarre, Mischer, Mulde und Kipper, und er entwickelt sich zu neuen SMASHs, einer verheerender als der andere. Du bringst deine Dateien im Nu in Ordnung, er wird zur Legende.\n\n(Ist SMASH aus, funktioniert das Schneiden genauso, aber Schutt wird nicht gezählt.)',
  );

  static String get continueCutting => _t(
    'Continua a tagliare',
    'Keep cutting',
    'Continuer à couper',
    'Seguir cortando',
    'Continuar cortando',
    'Weiterschneiden',
  );
  static String get shareCard => _t(
    'Condividi',
    'Share',
    'Partager',
    'Compartir',
    'Compartilhar',
    'Teilen',
  );
  static String missingKg(String kg) => _t(
    'mancano $kg kg',
    '$kg kg to go',
    'encore $kg kg',
    'faltan $kg kg',
    'faltam $kg kg',
    'noch $kg kg',
  );
  static String eatenKg(String kg) => _t(
    'Il mio SMASH ha mangiato $kg kg di macerie!',
    'My SMASH has eaten $kg kg of rubble!',
    'Mon SMASH a mangé $kg kg de gravats !',
    '¡Mi SMASH se ha comido $kg kg de escombros!',
    'Meu SMASH já comeu $kg kg de entulho!',
    'Mein SMASH hat $kg kg Schutt gefressen!',
  );

  /// Separatore decimale: virgola in tutte le lingue tranne l'inglese.
  static bool get decimalComma => lang != AppLang.en;
}
