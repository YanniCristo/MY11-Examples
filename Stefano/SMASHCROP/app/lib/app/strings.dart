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
        'li vediamo. Non raccogliamo dati personali e non usiamo account. Sul dispositivo restano '
        'solo le tue preferenze (lingua, impostazioni) e il lavoro in corso (i tagli e una copia del '
        'file, che si cancella quando chiudi il lavoro), per poterlo riprendere. I file salvati non contengono posizione GPS né altri dati della foto originale.',
    'SmashCrop works on your device: photos and PDFs are not uploaded to any server and we never '
        'see them. We collect no personal data and use no accounts. Only your preferences (language, '
        'settings) and the work in progress (the cuts and a copy of the file, deleted when you close '
        'the work) stay on the device, so you can resume it. '
        'Saved files contain no GPS location or other data from the original photo.',
    'SmashCrop fonctionne sur votre appareil : les photos et PDF ne sont envoyés sur aucun serveur '
        'et nous ne les voyons pas. Nous ne collectons aucune donnée personnelle et n\'utilisons pas '
        'de compte. Seuls vos préférences (langue, réglages) et le travail en cours (les découpes et '
        'une copie du fichier, supprimée quand vous fermez le travail) restent sur l\'appareil, pour '
        'le reprendre. Les fichiers enregistrés ne contiennent ni '
        'position GPS ni autres données de la photo d\'origine.',
    'SmashCrop funciona en tu dispositivo: las fotos y los PDF no se suben a ningún servidor y no '
        'los vemos. No recogemos datos personales ni usamos cuentas. En el dispositivo solo quedan '
        'tus preferencias (idioma, ajustes) y el trabajo en curso (los cortes y una copia del archivo, '
        'que se borra al cerrar el trabajo), para poder retomarlo. '
        'Los archivos guardados no contienen la ubicación GPS ni otros datos de la foto original.',
    'O SmashCrop funciona no seu dispositivo: fotos e PDFs não são enviados para nenhum servidor e '
        'nós não os vemos. Não coletamos dados pessoais nem usamos contas. No dispositivo ficam só '
        'suas preferências (idioma, ajustes) e o trabalho em andamento (os cortes e uma cópia do '
        'arquivo, apagada quando você fecha o trabalho), para retomá-lo. '
        'Os arquivos salvos não contêm localização GPS nem outros dados da foto original.',
    'SmashCrop arbeitet auf deinem Gerät: Fotos und PDFs werden auf keinen Server hochgeladen und '
        'wir sehen sie nie. Wir sammeln keine persönlichen Daten und nutzen keine Konten. Auf dem '
        'Gerät bleiben nur deine Einstellungen (Sprache usw.) und die laufende Arbeit (die Schnitte und '
        'eine Kopie der Datei, die beim Schließen der Arbeit gelöscht wird), damit du sie fortsetzen '
        'kannst. Gespeicherte Dateien enthalten keinen GPS-Standort und keine '
        'anderen Daten des Originalfotos.',
  );
  static String get close =>
      _t('Chiudi', 'Close', 'Fermer', 'Cerrar', 'Fechar', 'Schließen');
  static String get version =>
      _t('Versione', 'Version', 'Version', 'Versión', 'Versão', 'Version');
}
