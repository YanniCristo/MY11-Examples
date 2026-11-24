import 'dart:math' as math;
import 'dart:ui';

/// Le quattro impaginazioni di una pagina PDF modificata, in questo ordine.
enum PdfLayoutMode { centered, top, shrink, custom }

extension PdfLayoutModeLabel on PdfLayoutMode {
  String get label => switch (this) {
    PdfLayoutMode.centered => 'Centrato',
    PdfLayoutMode.top => 'In alto',
    PdfLayoutMode.shrink => 'Riduci pagina',
    PdfLayoutMode.custom => 'Personalizza posizione',
  };
}

/// Impaginazione scelta per una pagina. Per [PdfLayoutMode.custom]
/// [offset] è la posizione del contenuto nel foglio, in pixel di lavoro.
class PageLayout {
  const PageLayout(this.mode, [this.offset = Offset.zero]);

  final PdfLayoutMode mode;
  final Offset offset;

  @override
  bool operator ==(Object other) =>
      other is PageLayout && other.mode == mode && other.offset == offset;
  @override
  int get hashCode => Object.hash(mode, offset);
  @override
  String toString() => 'PageLayout(${mode.name}, $offset)';
}

/// Foglio di uscita e posizione del contenuto ricongiunto.
///
/// Il contenuto non viene mai ridimensionato: cambia solo il foglio
/// (Riduci pagina) o dove il contenuto sta dentro il foglio (le altre tre).
class PageFrame {
  const PageFrame(this.size, this.contentOffset, this.contentSize);

  /// Dimensioni del foglio di uscita.
  final Size size;
  final Offset contentOffset;
  final Size contentSize;

  Rect get contentRect => contentOffset & contentSize;

  /// [original]: foglio originale. [content]: contenuto dopo i tagli.
  /// [layout] `null` significa "nessun taglio": foglio e contenuto coincidono.
  factory PageFrame.compute({
    required Size original,
    required Size content,
    required PageLayout? layout,
  }) {
    if (layout == null) return PageFrame(content, Offset.zero, content);
    final freeX = math.max(0.0, original.width - content.width);
    final freeY = math.max(0.0, original.height - content.height);
    switch (layout.mode) {
      case PdfLayoutMode.centered:
        return PageFrame(original, Offset(freeX / 2, freeY / 2), content);
      case PdfLayoutMode.top:
        // in alto (e a sinistra, se il contenuto è più stretto del foglio)
        return PageFrame(original, Offset.zero, content);
      case PdfLayoutMode.shrink:
        return PageFrame(content, Offset.zero, content);
      case PdfLayoutMode.custom:
        return PageFrame(
          original,
          clampOffset(layout.offset, original, content),
          content,
        );
    }
  }

  /// Tiene il contenuto tutto dentro il foglio.
  static Offset clampOffset(Offset o, Size original, Size content) => Offset(
    o.dx.clamp(0.0, math.max(0.0, original.width - content.width)).toDouble(),
    o.dy.clamp(0.0, math.max(0.0, original.height - content.height)).toDouble(),
  );
}
