import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

import '../../editor/application/editor_page.dart';
import '../../image_processing/domain/raster_image.dart';
import '../domain/page_layout.dart';

/// Chiede la password all'utente. [wrong] è vero se la precedente era
/// sbagliata. Restituisce `null` se l'utente rinuncia.
typedef PasswordPrompt = Future<String?> Function({required bool wrong});

class PdfOpenException implements Exception {
  PdfOpenException({
    this.password = false,
    this.cancelled = false,
    this.locked = false,
    this.detail,
  });

  /// Errore tecnico originale, mostrato per capire cosa non va.
  final String? detail;

  /// Password richiesta ma non fornita.
  final bool password;

  /// L'utente ha annullato l'inserimento della password.
  final bool cancelled;

  /// Il proprietario del PDF non consente di modificarlo.
  final bool locked;
}

/// Un PDF aperto: il documento originale resta aperto finché si lavora,
/// così le pagine non modificate si copiano intatte nel file finale.
class PdfSession {
  PdfSession._(this.document, this.name);

  final PdfDocument document;
  final String name;

  /// Risoluzione sullo schermo: basta per leggere bene anche ingrandendo, e
  /// resta leggera. Nel browser (iPhone in particolare) la memoria è poca:
  /// pagine troppo grandi fanno ricaricare la pagina web.
  static const double displayDpi = kIsWeb ? 150 : 200;
  static const double displayMaxSidePx = kIsWeb ? 2000 : 2600;

  /// Risoluzione del file salvato: 300 DPI, qualità di stampa. Ogni pagina
  /// tagliata si rende di nuovo a questa risoluzione solo al salvataggio,
  /// una alla volta, e la memoria si libera subito dopo.
  static const double exportDpi = 300;
  static const double exportMaxSidePx = kIsWeb ? 4000 : 5000;

  static double _scale(ui.Size pt, double dpi, double maxSide) =>
      math.min(dpi / 72, maxSide / math.max(pt.width, pt.height));

  /// Apre il PDF. Se è protetto, la password la inserisce l'utente con
  /// [askPassword]: l'app non prova mai ad aggirare la protezione.
  static Future<PdfSession> open(
    Uint8List bytes,
    String name, {
    PasswordPrompt? askPassword,
  }) async {
    var attempts = 0;
    var cancelled = false;
    try {
      final doc = await PdfDocument.openData(
        bytes,
        sourceName: 'smashcrop:$name:${bytes.length}',
        passwordProvider: askPassword == null
            ? null
            : () async {
                final pw = await askPassword(wrong: attempts > 0);
                attempts++;
                if (pw == null) cancelled = true;
                return pw;
              },
      );
      if (doc.pages.isEmpty) {
        await doc.dispose();
        throw PdfOpenException(detail: 'nessuna pagina');
      }
      // rispetta i permessi del documento: se il proprietario non consente
      // di modificarlo, non lo si apre per la modifica
      // (bit 4 dei permessi PDF, valore 8: "modificare il contenuto")
      final perms = doc.permissions;
      final modifyAllowed = perms != null
          ? (!doc.isEncrypted || (perms.permissions & 8) != 0)
          : (scanModifyPermission(bytes) ?? true);
      if (!modifyAllowed) {
        await doc.dispose();
        throw PdfOpenException(locked: true);
      }
      return PdfSession._(doc, name);
    } on PdfPasswordException {
      throw PdfOpenException(password: true, cancelled: cancelled);
    } on PdfOpenException {
      rethrow;
    } catch (e) {
      throw PdfOpenException(detail: '$e');
    }
  }

  /// Lettura diretta del dizionario /Encrypt, usata quando il motore PDF
  /// non riporta i permessi (succede nella versione web). `null` se il file
  /// non è cifrato o il dato non si trova.
  @visibleForTesting
  static bool? scanModifyPermission(Uint8List bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    final ref = RegExp(r'/Encrypt\s+(\d+)\s+(\d+)\s+R')
        .allMatches(text)
        .lastOrNull;
    String? dict;
    if (ref != null) {
      final obj = RegExp(
        '(?:^|[^0-9])${ref.group(1)}\\s+${ref.group(2)}\\s+obj(.*?)endobj',
        dotAll: true,
      ).allMatches(text).lastOrNull;
      dict = obj?.group(1);
    } else {
      final inline = RegExp(
        r'/Encrypt\s*<<(.*?)>>',
        dotAll: true,
      ).allMatches(text).lastOrNull;
      dict = inline?.group(1);
    }
    if (dict == null) return null;
    final p = RegExp(r'/P\s+(-?\d+)').firstMatch(dict);
    if (p == null) return null;
    final value = int.parse(p.group(1)!);
    return (value & 8) != 0;
  }

  int get pageCount => document.pages.length;

  /// Crea le pagine di lavoro (ancora senza immagine: si rendono quando servono).
  List<EditorPage> createPages() {
    return [
      for (final p in document.pages)
        () {
          final scale = _scale(
            ui.Size(p.width, p.height),
            displayDpi,
            displayMaxSidePx,
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
        // la pagina si rende di nuovo a 300 DPI; i tagli fatti sullo
        // schermo si riportano in proporzione
        final pt = page.originalPointSize!;
        final k = _scale(pt, exportDpi, exportMaxSidePx);
        final ew = math.max(1, (pt.width * k).round());
        final eh = math.max(1, (pt.height * k).round());
        final source = await document.pages[page.index].renderForDisplay(
          width: ew,
          height: eh,
          fullWidth: ew.toDouble(),
          fullHeight: eh.toDouble(),
          backgroundColor: 0xFFFFFFFF,
        );
        if (source == null) {
          throw StateError('Pagina ${page.index + 1} non resa');
        }
        try {
          final data = await source.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          final doc = page.doc.rescaled(ew, eh);
          final layout = page.effectiveLayout(suggestion);
          final sx = ew / page.widthPx, sy = eh / page.heightPx;
          final frame = PageFrame.compute(
            original: ui.Size(ew.toDouble(), eh.toDouble()),
            content: ui.Size(doc.width.toDouble(), doc.height.toDouble()),
            layout: layout?.mode == PdfLayoutMode.custom
                ? PageLayout(
                    PdfLayoutMode.custom,
                    ui.Offset(layout!.offset.dx * sx, layout.offset.dy * sy),
                  )
                : layout,
          );
          final job = _PageJob(
            rgba: data!.buffer.asUint8List(),
            srcW: source.width,
            srcH: source.height,
            contentW: doc.width,
            contentH: doc.height,
            tiles: doc.tiles(),
            frameW: frame.size.width.round(),
            frameH: frame.size.height.round(),
            offsetX: frame.contentOffset.dx.round(),
            offsetY: frame.contentOffset.dy.round(),
          );
          final jpeg = await compute(_encodePage, job);
          // da pixel a punti con il rapporto esatto della pagina originale:
          // un foglio che non cambia misura resta identico al millimetro
          final d = await PdfDocument.createFromJpegData(
            jpeg,
            width: frame.size.width * pt.width / ew,
            height: frame.size.height * pt.height / eh,
            sourceName:
                'smashcrop-page-${page.index}-${DateTime.now().microsecondsSinceEpoch}',
          );
          temps.add(d);
          list.add(d.pages.first);
        } finally {
          source.dispose();
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
  return img.encodeJpg(image, quality: 100, chroma: img.JpegChroma.yuv444);
}
