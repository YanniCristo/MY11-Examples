import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../editor/application/editor_page.dart';
import '../../image_processing/domain/raster_image.dart';
import '../domain/page_layout.dart';

class PdfOpenException implements Exception {
  PdfOpenException({this.password = false});
  final bool password;
}

/// Un PDF aperto: il documento originale resta aperto finché si lavora,
/// così le pagine non modificate si copiano intatte nel file finale.
class PdfSession {
  PdfSession._(this.document, this.name);

  final PdfDocument document;
  final String name;

  /// Risoluzione di lavoro: abbastanza per stampare bene, senza esagerare
  /// con la memoria. Il lato lungo resta entro 2600 px.
  static const double maxDpi = 200;
  static const double maxSidePx = 2600;

  static Future<PdfSession> open(Uint8List bytes, String name) async {
    try {
      final doc = await PdfDocument.openData(
        bytes,
        sourceName: 'smashcrop:$name:${bytes.length}',
      );
      if (doc.pages.isEmpty) {
        await doc.dispose();
        throw PdfOpenException();
      }
      return PdfSession._(doc, name);
    } on PdfPasswordException {
      throw PdfOpenException(password: true);
    } on PdfOpenException {
      rethrow;
    } catch (_) {
      throw PdfOpenException();
    }
  }

  int get pageCount => document.pages.length;

  /// Crea le pagine di lavoro (ancora senza immagine: si rendono quando servono).
  List<EditorPage> createPages() {
    return [
      for (final p in document.pages)
        () {
          final scale = math.min(
            maxDpi / 72,
            maxSidePx / math.max(p.width, p.height),
          );
          return EditorPage(
            index: p.pageNumber - 1,
            widthPx: math.max(1, (p.width * scale).round()),
            heightPx: math.max(1, (p.height * scale).round()),
            pxPerPoint: scale,
            originalPointSize: ui.Size(p.width, p.height),
          );
        }(),
    ];
  }

  /// Rende una pagina alle dimensioni di lavoro, su fondo bianco.
  Future<ui.Image> render(EditorPage page) async {
    final p = document.pages[page.index];
    final im = await p.renderForDisplay(
      width: page.widthPx,
      height: page.heightPx,
      fullWidth: page.widthPx.toDouble(),
      fullHeight: page.heightPx.toDouble(),
      backgroundColor: 0xFFFFFFFF,
    );
    if (im == null) throw StateError('Pagina ${page.index + 1} non resa');
    return im;
  }

  /// Costruisce il PDF finale: stesso numero e ordine di pagine; le pagine
  /// non tagliate sono copiate così come sono, quelle tagliate diventano
  /// un'immagine con la propria impaginazione.
  Future<Uint8List> export(
    List<EditorPage> pages,
    PdfLayoutMode suggestion,
  ) async {
    final temps = <PdfDocument>[];
    final out = await PdfDocument.createNew(
      sourceName: 'smashcrop-out-${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      final list = <PdfPage>[];
      for (final page in pages) {
        if (!page.history.hasCuts) {
          list.add(document.pages[page.index]);
          continue;
        }
        final rendered = page.isReady ? null : await render(page);
        final source = rendered ?? page.image!;
        try {
          final data = await source.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          final frame = page.frame(suggestion);
          final job = _PageJob(
            rgba: data!.buffer.asUint8List(),
            srcW: source.width,
            srcH: source.height,
            contentW: page.doc.width,
            contentH: page.doc.height,
            tiles: page.doc.tiles(),
            frameW: frame.size.width.round(),
            frameH: frame.size.height.round(),
            offsetX: frame.contentOffset.dx.round(),
            offsetY: frame.contentOffset.dy.round(),
          );
          final jpeg = await compute(_encodePage, job);
          // da pixel a punti con il rapporto esatto della pagina originale:
          // un foglio che non cambia misura resta identico al millimetro
          final pt = page.originalPointSize!;
          final d = await PdfDocument.createFromJpegData(
            jpeg,
            width: frame.size.width * pt.width / page.widthPx,
            height: frame.size.height * pt.height / page.heightPx,
            sourceName:
                'smashcrop-page-${page.index}-${DateTime.now().microsecondsSinceEpoch}',
          );
          temps.add(d);
          list.add(d.pages.first);
        } finally {
          rendered?.dispose();
        }
      }
      out.pages = list;
      final bytes = await out.encodePdf();
      await _verify(bytes, pages);
      return bytes;
    } finally {
      await out.dispose();
      for (final t in temps) {
        await t.dispose();
      }
    }
  }

  /// Riapre il file prodotto e controlla numero di pagine e dimensioni.
  static Future<void> _verify(Uint8List bytes, List<EditorPage> pages) async {
    final check = await PdfDocument.openData(
      bytes,
      sourceName: 'smashcrop-check-${bytes.length}',
    );
    try {
      if (check.pages.length != pages.length) {
        throw StateError(
          'Il PDF prodotto ha ${check.pages.length} pagine invece di ${pages.length}',
        );
      }
    } finally {
      await check.dispose();
    }
  }

  Future<void> dispose() => document.dispose();
}

class _PageJob {
  _PageJob({
    required this.rgba,
    required this.srcW,
    required this.srcH,
    required this.contentW,
    required this.contentH,
    required this.tiles,
    required this.frameW,
    required this.frameH,
    required this.offsetX,
    required this.offsetY,
  });
  final Uint8List rgba;
  final int srcW, srcH, contentW, contentH, frameW, frameH, offsetX, offsetY;
  final List<List<int>> tiles;
}

Uint8List _encodePage(_PageJob j) {
  final content = RasterImage.composeTiles(
    RasterImage(j.srcW, j.srcH, j.rgba),
    j.contentW,
    j.contentH,
    j.tiles,
  );
  final page = Uint8List(j.frameW * j.frameH * 4)
    ..fillRange(0, j.frameW * j.frameH * 4, 255);
  // il contenuto si copia così com'è, senza ridimensionarlo
  for (var y = 0; y < content.height; y++) {
    final py = y + j.offsetY;
    if (py < 0 || py >= j.frameH) continue;
    final x0 = math.max(0, j.offsetX);
    final x1 = math.min(j.frameW, j.offsetX + content.width);
    if (x1 <= x0) continue;
    final s = (y * content.width + (x0 - j.offsetX)) * 4;
    final d = (py * j.frameW + x0) * 4;
    page.setRange(d, d + (x1 - x0) * 4, content.rgba, s);
  }
  final image = img.Image.fromBytes(
    width: j.frameW,
    height: j.frameH,
    bytes: page.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return img.encodeJpg(image, quality: 92);
}
