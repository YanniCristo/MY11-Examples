import 'cut_operation.dart';
import 'strip_document.dart';

/// Cronologia non distruttiva: l'originale resta intatto e ogni stato si
/// ricostruisce dall'originale applicando le operazioni fino al cursore.
class EditHistory {
  EditHistory(this.original);

  final StripDocument original;
  final List<CutOperation> _ops = [];
  int _cursor = 0;

  List<CutOperation> get operations => List.unmodifiable(_ops.take(_cursor));
  int get length => _ops.length;
  int get cursor => _cursor;
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _ops.length;
  bool get isModified => _cursor > 0;

  /// Documento allo stato attuale.
  StripDocument get current {
    var doc = original;
    for (var i = 0; i < _cursor; i++) {
      doc = doc.apply(_ops[i]);
    }
    return doc;
  }

  /// Registra un nuovo taglio. Se c'erano passi annullati, il ramo di Redo
  /// incompatibile viene eliminato.
  void push(CutOperation op) {
    if (_cursor < _ops.length) _ops.removeRange(_cursor, _ops.length);
    _ops.add(op);
    _cursor = _ops.length;
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
