import '../../octo/domain/ink_fill.dart';
import '../../pdf_processing/domain/page_layout.dart';
import 'cut_operation.dart';
import 'strip_document.dart';

/// Un passo della cronologia: un taglio oppure un cambio di impaginazione.
sealed class EditStep {
  const EditStep();
}

class CutStep extends EditStep {
  const CutStep(this.op);
  final CutOperation op;
}

/// Rettangoli d'inchiostro spruzzati insieme da OctoSmash (un "Fatto").
class FillStep extends EditStep {
  const FillStep(this.fills);
  final List<InkFill> fills;
}

class LayoutStep extends EditStep {
  const LayoutStep(this.layout);
  final PageLayout layout;
}

/// Cronologia non distruttiva: l'originale resta intatto e ogni stato si
/// ricostruisce dall'originale applicando i passi fino al cursore.
class EditHistory {
  EditHistory(this.original);

  final StripDocument original;
  final List<EditStep> _steps = [];
  int _cursor = 0;

  int get length => _steps.length;
  int get cursor => _cursor;
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _steps.length;

  Iterable<EditStep> get _applied => _steps.take(_cursor);

  /// Passi applicati, nell'ordine (per salvare il lavoro).
  List<EditStep> get appliedSteps => _applied.toList();

  /// Documento allo stato attuale.
  StripDocument get current {
    var doc = original;
    for (final s in _applied) {
      if (s is CutStep) doc = doc.apply(s.op);
    }
    return doc;
  }

  /// Ultima impaginazione scelta, o `null` se non è mai stata scelta.
  PageLayout? get layout {
    PageLayout? l;
    for (final s in _applied) {
      if (s is LayoutStep) l = s.layout;
    }
    return l;
  }

  /// Vero se c'è almeno un taglio applicato.
  bool get hasCuts => _applied.any((s) => s is CutStep);

  /// Rettangoli d'inchiostro applicati (coordinate dell'originale).
  List<InkFill> get fills => [
    for (final s in _applied)
      if (s is FillStep) ...s.fills,
  ];

  bool get hasFills => _applied.any((s) => s is FillStep);

  void pushFills(List<InkFill> f) => _add(FillStep(f));

  /// Registra un nuovo taglio. Se c'erano passi annullati, il ramo di Redo
  /// incompatibile viene eliminato.
  void push(CutOperation op) => _add(CutStep(op));

  void pushLayout(PageLayout layout) => _add(LayoutStep(layout));

  void _add(EditStep s) {
    if (_cursor < _steps.length) _steps.removeRange(_cursor, _steps.length);
    _steps.add(s);
    _cursor = _steps.length;
  }

  bool undo() {
    if (!canUndo) return false;
    _cursor--;
    return true;
  }

  bool redo() {
    if (!canRedo) return false;
    _cursor++;
    return true;
  }
}
