import '../octo/domain/ink_fill.dart';

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../editor/domain/strip_document.dart';
import '../image_processing/services/image_loader.dart';
import 'export_service.dart';

/// Una pagina del PDF fatto di immagini.
class ImagePdfPage {
  ImagePdfPage(this.file, this.doc, this.pixels, {this.fills = const []});
  final ImageFile file;
  final StripDocument doc;

  /// Inchiostri di OctoSmash della pagina.
  final List<InkFill> fills;

  /// Pixel decodificati dal sistema, solo se il file non si legge qui (HEIC).
  final Future<ui.Image> Function() pixels;
}

/// Lato lungo dell'immagine originale nel PDF: quello di un A4 (in punti).
/// Le pagine tagliate restano in proporzione, quindi più piccole.
const double kImagePageLongSidePt = 842;

/// Costruisce un PDF con un'immagine per pagina, nell'ordine dato. Ogni
/// pagina ha la misura della sua immagine (nessun bordo bianco aggiunto).
Future<Uint8List> buildImagesPdf(
  List<ImagePdfPage> pages, {
  ExportService exporter = const ExportService(),
}) async {
  final temps = <PdfDocument>[];
  final out = await PdfDocument.createNew(
    sourceName: 'smashcrop-img-${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    final list = <PdfPage>[];
    for (var i = 0; i < pages.length; i++) {
      final p = pages[i];
      final jpeg = await pageJpeg(p, exporter);
      final k = kImagePageLongSidePt / math.max(p.file.width, p.file.height);
      final d = await PdfDocument.createFromJpegData(
        jpeg,
        width: p.doc.width * k,
        height: p.doc.height * k,
        sourceName: 'smashcrop-img-$i-${DateTime.now().microsecondsSinceEpoch}',
      );
      temps.add(d);
      list.add(d.pages.first);
    }
    out.pages = list;
    final bytes = await out.encodePdf();
    final check = await PdfDocument.openData(
      bytes,
      sourceName: 'smashcrop-img-check-${bytes.length}',
    );
    try {
      if (check.pages.length != pages.length) {
        throw StateError(
          'PDF con ${check.pages.length} pagine invece di ${pages.length}',
        );
      }
    } finally {
      await check.dispose();
    }
    return bytes;
  } finally {
    await out.dispose();
    for (final t in temps) {
      await t.dispose();
    }
  }
}

/// Il JPEG della pagina. Una foto JPEG non tagliata e già dritta entra così
/// com'è (nessuna perdita), tolti solo i dati EXIF e la posizione GPS;
/// tutto il resto si codifica in JPEG alla qualità massima.
Future<Uint8List> pageJpeg(ImagePdfPage p, ExportService exporter) async {
  final b = p.file.bytes;
  final uncut =
      p.fills.isEmpty &&
      p.doc.width == p.file.width &&
      p.doc.height == p.file.height;
  if (b != null && uncut && p.file.format == OutputFormat.jpeg && _upright(b)) {
    final clean = stripJpegMetadata(b);
    if (clean != null) return clean;
  }
  final f = await exporter.buildFile(
    p.file,
    p.doc,
    pixels: p.pixels,
    format: OutputFormat.jpeg,
    flattenOnWhite: true,
    fills: p.fills,
  );
  return f.bytes;
}

bool _upright(Uint8List jpeg) {
  try {
    final o = img.decodeJpgExif(jpeg)?.imageIfd.orientation ?? 1;
    return o == 1;
  } catch (_) {
    return false;
  }
}

/// Toglie dal JPEG i blocchi APP1 (EXIF, XMP: data, telefono, GPS) e i
/// commenti, senza toccare l'immagine. Il profilo colore (APP2) resta.
/// `null` se il file non ha la struttura attesa.
Uint8List? stripJpegMetadata(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;
  final out = BytesBuilder(copy: false)..add([0xFF, 0xD8]);
  var i = 2;
  while (i + 4 <= b.length) {
    if (b[i] != 0xFF) return null;
    final m = b[i + 1];
    if (m == 0xFF) {
      i++;
      continue;
    }
    if (m == 0xDA) {
      // inizio dei dati dell'immagine: il resto si copia com'è
      out.add(Uint8List.sublistView(b, i));
      return out.toBytes();
    }
    if (m == 0x01 || (m >= 0xD0 && m <= 0xD7)) {
      out.add(Uint8List.sublistView(b, i, i + 2));
      i += 2;
      continue;
    }
    final len = (b[i + 2] << 8) | b[i + 3];
    final end = i + 2 + len;
    if (len < 2 || end > b.length) return null;
    if (m != 0xE1 && m != 0xFE) out.add(Uint8List.sublistView(b, i, end));
    i = end;
  }
  return null;
}
