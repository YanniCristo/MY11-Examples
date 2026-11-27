import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Si chiude trascinando verso il basso, come le schermate "sopra" di iPhone.
/// Funziona sia trascinando le parti ferme, sia tirando giù una lista che è
/// già in cima. Rilasciando: oltre una certa distanza (o con un gesto
/// veloce) si chiude, altrimenti torna su.
class SwipeDownToClose extends StatefulWidget {
  const SwipeDownToClose({super.key, required this.child, this.onClose});

  final Widget child;

  /// Di solito `Navigator.pop`.
  final VoidCallback? onClose;

  @override
  State<SwipeDownToClose> createState() => _SwipeDownToCloseState();
}

class _SwipeDownToCloseState extends State<SwipeDownToClose>
    with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => setState(() => _dy = _from * (1 - _back.value)));

  double _dy = 0; // di quanto è scesa la pagina
  double _from = 0;
  bool _closing = false;

  static const _distance = 130.0; // oltre: si chiude
  static const _speed = 900.0; // gesto veloce: si chiude subito

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _move(double d) {
    if (_closing) return;
    _back.stop();
    setState(() => _dy = (_dy + d).clamp(0, double.infinity));
  }

  void _release(double velocity) {
    if (_closing || _dy == 0) return;
    if (_dy > _distance || velocity > _speed) {
      _closing = true;
      HapticFeedback.lightImpact();
      (widget.onClose ?? () => Navigator.of(context).maybePop())();
      return;
    }
    _from = _dy;
    _back.forward(from: 0);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    // lista già in cima e il dito tira giù: scende la pagina
    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      _move(-n.overscroll);
    } else if (n is ScrollUpdateNotification &&
        n.dragDetails != null &&
        n.metrics.pixels < n.metrics.minScrollExtent) {
      // iPhone: la lista "rimbalza" oltre la cima
      _move(-(n.scrollDelta ?? 0));
    } else if (n is ScrollUpdateNotification &&
        n.dragDetails != null &&
        _dy > 0 &&
        (n.scrollDelta ?? 0) > 0) {
      // il dito torna su: prima risale la pagina
      _move(-(n.scrollDelta ?? 0));
    } else if (n is ScrollEndNotification) {
      _release(n.dragDetails?.velocity.pixelsPerSecond.dy ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (d) => _move(d.delta.dy),
      onVerticalDragEnd: (d) => _release(d.velocity.pixelsPerSecond.dy),
      onVerticalDragCancel: () => _release(0),
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Transform.translate(
          offset: Offset(0, _dy),
          child: Opacity(
            opacity: (1 - _dy / h * .8).clamp(.4, 1.0),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
