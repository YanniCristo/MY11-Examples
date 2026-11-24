import 'dart:convert';
import 'dart:ui' show Offset;

import '../../pdf_processing/domain/page_layout.dart';
import '../domain/cut_operation.dart';
import '../domain/edit_history.dart';
import 'editor_page.dart';

/// Il lavoro in corso, salvato sul dispositivo a ogni modifica: se la
/// pagina web si ricarica (o l'app viene chiusa) si riprende da qui.
///
/// Contiene solo il nome e il peso del file, per riconoscerlo quando lo si
/// riapre, e i tagli fatti: mai il contenuto del file.
class SavedWork {
  SavedWork({
    required this.isPdf,
    required this.name,
    required this.size,
    required this.pageIndex,
    required this.pages,
    this.nextPagesLayout,
  });

  final bool isPdf;
  final String name;
  final int size;
  final int pageIndex;
  final Map<int, SavedPage> pages;
  final PdfLayoutMode? nextPagesLayout;

  int get cutCount =>
      pages.values.fold(0, (n, p) => n + p.steps.whereType<CutStep>().length);

  bool matches({
    required bool isPdf,
    required String name,
    required int size,
  }) => this.isPdf == isPdf && this.name == name && this.size == size;

  static SavedWork? capture({
    required bool isPdf,
    required String name,
    required int size,
    required int pageIndex,
    required List<EditorPage> pages,
    PdfLayoutMode? nextPagesLayout,
  }) {
    final saved = <int, SavedPage>{};
    for (final p in pages) {
      final steps = p.history.appliedSteps;
      if (steps.isNotEmpty) {
        saved[p.index] = SavedPage(p.widthPx, p.heightPx, steps);
      }
    }
    if (saved.isEmpty) return null;
    return SavedWork(
      isPdf: isPdf,
      name: name,
      size: size,
      pageIndex: pageIndex,
      pages: saved,
      nextPagesLayout: nextPagesLayout,
    );
  }

  /// Rifà i passi salvati sulle pagine appena aperte. Se la pagina ha una
  /// risoluzione di lavoro diversa (altro dispositivo) i tagli si riportano
  /// in proporzione. Restituisce il numero di pagine ripristinate.
  int replayOn(List<EditorPage> target) {
    var n = 0;
    for (final e in pages.entries) {
      if (e.key < 0 || e.key >= target.length) continue;
      final p = target[e.key];
      final rx = p.widthPx / e.value.width;
      final ry = p.heightPx / e.value.height;
      for (final s in e.value.steps) {
        switch (s) {
          case CutStep(:final op):
            final len = p.doc.lengthFor(op.orientation);
            final r = op.orientation == CutOrientation.horizontal ? ry : rx;
            final a = (op.start * r).round().clamp(0, len);
            final b = (op.end * r).round().clamp(0, len);
            if (b <= a || b - a >= len) continue;
            p.history.push(
              CutOperation(
                orientation: op.orientation,
                start: a,
                end: b,
                lengthBefore: len,
              ),
            );
          case LayoutStep(:final layout):
            p.history.pushLayout(
              PageLayout(
                layout.mode,
                Offset(layout.offset.dx * rx, layout.offset.dy * ry),
              ),
            );
        }
      }
      p.refreshView();
      n++;
    }
    return n;
  }

  String encode() => jsonEncode({
    'v': 1,
    'pdf': isPdf,
    'name': name,
    'size': size,
    'page': pageIndex,
    if (nextPagesLayout != null) 'next': nextPagesLayout!.name,
    'pages': {
      for (final e in pages.entries)
        '${e.key}': {
          'w': e.value.width,
          'h': e.value.height,
          's': [for (final s in e.value.steps) _stepToJson(s)],
        },
    },
  });

  static SavedWork? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['v'] != 1) return null;
      final pages = <int, SavedPage>{};
      (m['pages'] as Map<String, dynamic>).forEach((k, v) {
        final pm = v as Map<String, dynamic>;
        pages[int.parse(k)] = SavedPage(pm['w'] as int, pm['h'] as int, [
          for (final s in pm['s'] as List) _stepFromJson(s as List),
        ]);
      });
      final next = m['next'] as String?;
      return SavedWork(
        isPdf: m['pdf'] as bool,
        name: m['name'] as String,
        size: m['size'] as int,
        pageIndex: m['page'] as int,
        pages: pages,
        nextPagesLayout: next == null
            ? null
            : PdfLayoutMode.values.firstWhere((x) => x.name == next),
      );
    } catch (_) {
      return null;
    }
  }

  static List<Object> _stepToJson(EditStep s) => switch (s) {
    CutStep(:final op) => [
      'c',
      op.orientation.index,
      op.start,
      op.end,
      op.lengthBefore,
    ],
    LayoutStep(:final layout) => [
      'l',
      layout.mode.index,
      layout.offset.dx,
      layout.offset.dy,
    ],
  };

  static EditStep _stepFromJson(List j) => j[0] == 'c'
      ? CutStep(
          CutOperation(
            orientation: CutOrientation.values[j[1] as int],
            start: j[2] as int,
            end: j[3] as int,
            lengthBefore: j[4] as int,
          ),
        )
      : LayoutStep(
          PageLayout(
            PdfLayoutMode.values[j[1] as int],
            Offset((j[2] as num).toDouble(), (j[3] as num).toDouble()),
          ),
        );
}

class SavedPage {
  SavedPage(this.width, this.height, this.steps);
  final int width;
  final int height;
  final List<EditStep> steps;
}
