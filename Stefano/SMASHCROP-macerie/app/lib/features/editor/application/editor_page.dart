import 'dart:ui' as ui;

import '../../pdf_processing/domain/page_layout.dart';
import '../domain/edit_history.dart';
import '../domain/selection_state.dart';
import '../domain/strip_document.dart';
import 'doc_source.dart';

/// Una pagina in lavorazione: l'immagine importata, oppure una pagina PDF
/// resa in pixel. Ogni pagina ha la propria cronologia, la propria
/// selezione e la propria impaginazione.
class EditorPage {
  EditorPage({
    required this.index,
    required this.widthPx,
    required this.heightPx,
    this.pxPerPoint = 1,
    this.originalPointSize,
    ui.Image? image,
  }) : history = EditHistory(StripDocument.original(widthPx, heightPx)),
       selection = SelectionState.initial(width: widthPx, height: heightPx) {
    if (image != null) attach(image);
  }

  /// Posizione nel documento (per le immagini cambia se si toglie una pagina).
  int index;

  /// Dimensioni della pagina resa (pixel di lavoro): tutti i tagli e le
  /// posizioni sono espressi in queste unità.
  final int widthPx;
  final int heightPx;

  /// Pixel di lavoro per punto PDF (1/72 di pollice). 1 per le immagini.
  final double pxPerPoint;

  /// Dimensioni originali della pagina PDF in punti, `null` per le immagini.
  final ui.Size? originalPointSize;

  final EditHistory history;
  SelectionState selection;

  ui.Image? _image;
  DocSource? _view;

  bool get isReady => _image != null;
  ui.Image? get image => _image;
  ui.Size get originalSize => ui.Size(widthPx.toDouble(), heightPx.toDouble());
  StripDocument get doc => history.current;

  /// Vista del documento attuale; ricostruita quando cambia la cronologia.
  DocSource get view => _view!;

  void attach(ui.Image image) {
    _image = image;
    refreshView();
  }

  /// Libera l'immagine resa (si può sempre rifare: la resa è deterministica).
  void evict() {
    _view?.dispose();
    _view = null;
    _image?.dispose();
    _image = null;
  }

  void refreshView() {
    final img = _image;
    if (img == null) return;
    final old = _view;
    _view = DocSource.build(img, doc);
    old?.dispose();
  }

  /// Sostituisce la vista con una già pronta (alla fine di un taglio).
  /// La vista precedente appartiene all'animazione, che la libera alla fine.
  void adoptView(DocSource v) => _view = v;

  /// Impaginazione da usare: quella scelta, oppure il suggerimento se la
  /// pagina è tagliata ma non è ancora stata scelta. Le immagini non ne hanno.
  PageLayout? effectiveLayout(PdfLayoutMode suggestion) {
    if (originalPointSize == null || !history.hasCuts) return null;
    return history.layout ?? PageLayout(suggestion);
  }

  PageFrame frame(PdfLayoutMode suggestion, {PageLayout? override}) {
    final d = doc;
    return PageFrame.compute(
      original: originalSize,
      content: ui.Size(d.width.toDouble(), d.height.toDouble()),
      layout: override ?? effectiveLayout(suggestion),
    );
  }
}
