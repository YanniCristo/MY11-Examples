import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

/// Scelta delle immagini nel browser.
///
/// Su iPhone Safari il menu (Libreria foto / Scatta foto / Scegli file)
/// nasce dall'elemento toccato dal dito. In un'app Flutter quell'elemento è
/// tutta la pagina, e il menu partiva da un grosso cerchio bianco in mezzo
/// allo schermo. Come nelle pagine normali, qui il dito tocca davvero un
/// campo file trasparente messo sopra il pulsante ([ImagePickTarget]): il
/// menu nasce dal pulsante, senza cerchio.

Completer<List<XFile>>? _armed;

List<XFile> _filesOf(web.HTMLInputElement input) {
  final list = input.files;
  final out = <XFile>[];
  if (list == null) return out;
  for (var i = 0; i < list.length; i++) {
    final f = list.item(i);
    if (f == null) continue;
    out.add(
      XFile(
        web.URL.createObjectURL(f),
        name: f.name,
        length: f.size,
        mimeType: f.type,
      ),
    );
  }
  return out;
}

double _x = 0, _y = 0;
bool _watching = false;

/// Tiene a mente dove l'utente ha toccato per ultimo (per il caso di
/// riserva, quando il campo trasparente non c'è).
void watchPointerWeb() {
  if (_watching) return;
  _watching = true;
  web.window.addEventListener(
    'pointerdown',
    ((web.PointerEvent e) {
      _x = e.clientX.toDouble();
      _y = e.clientY.toDouble();
    }).toJS,
    true.toJS,
  );
}

/// Le immagini scelte. Se il tocco è arrivato dal campo trasparente si
/// aspetta la sua scelta; altrimenti (riserva) si apre un campo dal codice.
Future<List<XFile>> pickImagesWeb() {
  final armed = _armed;
  if (armed != null) {
    _armed = null;
    return armed.future;
  }
  final done = Completer<List<XFile>>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = true
    ..accept = 'image/*';
  input.style
    ..position = 'fixed'
    ..left = '${(_x - 24).round()}px'
    ..top = '${(_y - 24).round()}px'
    ..width = '48px'
    ..height = '48px'
    ..opacity = '0'
    ..pointerEvents = 'none';
  void finish(List<XFile> f) {
    if (done.isCompleted) return;
    done.complete(f);
    Timer(const Duration(seconds: 1), () => input.remove());
  }

  input.addEventListener(
    'change',
    ((web.Event _) => finish(_filesOf(input))).toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => finish(const [])).toJS);
  web.document.body?.append(input);
  input.click();
  return done.future;
}

/// Mette un campo file trasparente esattamente sopra [child]. Il tocco apre
/// la scelta delle foto del browser e chiama [onTap], che poi riceve i file
/// da `pickImagesWeb()`. Con [onTap] `null` il campo sparisce.
class ImagePickTarget extends StatefulWidget {
  const ImagePickTarget({super.key, required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<ImagePickTarget> createState() => _ImagePickTargetState();
}

class _ImagePickTargetState extends State<ImagePickTarget>
    with SingleTickerProviderStateMixin {
  final _key = GlobalKey();
  late final Ticker _ticker = createTicker((_) => _place());
  web.HTMLInputElement? _input;
  String _last = '';

  @override
  void initState() {
    super.initState();
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..multiple = true
      ..accept = 'image/*';
    input.style
      ..position = 'fixed'
      ..opacity = '0'
      ..margin = '0'
      ..padding = '0'
      ..border = '0'
      ..cursor = 'pointer'
      ..zIndex = '2147483646'
      ..display = 'none';
    input.addEventListener(
      'click',
      ((web.Event _) {
        // si arma prima di onTap: pickImagesWeb consegnerà questa scelta
        _waiting?.complete(const []);
        final c = Completer<List<XFile>>();
        _waiting = c;
        _armed = c;
        widget.onTap?.call();
      }).toJS,
    );
    input.addEventListener(
      'change',
      ((web.Event _) {
        _complete(_filesOf(input));
        input.value = '';
      }).toJS,
    );
    input.addEventListener(
      'cancel',
      ((web.Event _) => _complete(const [])).toJS,
    );
    web.document.body?.append(input);
    _input = input;
    _ticker.start();
  }

  /// La scelta in corso: chi aspetta i file (onTap → pickMany →
  /// pickImagesWeb) li riceve qui.
  Completer<List<XFile>>? _waiting;

  void _complete(List<XFile> files) {
    final c = _waiting;
    _waiting = null;
    if (c != null && !c.isCompleted) c.complete(files);
  }

  void _place() {
    final input = _input;
    if (input == null) return;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    final route = ModalRoute.of(context);
    final show =
        widget.onTap != null &&
        box != null &&
        box.attached &&
        box.hasSize &&
        (route?.isCurrent ?? true) &&
        TickerMode.valuesOf(context).enabled;
    String spec;
    if (!show) {
      spec = 'none';
    } else {
      final r = box.localToGlobal(Offset.zero) & box.size;
      spec =
          '${r.left.round()},${r.top.round()},'
          '${r.width.round()},${r.height.round()}';
    }
    if (spec == _last) return;
    _last = spec;
    if (spec == 'none') {
      input.style.display = 'none';
      return;
    }
    final p = spec.split(',');
    input.style
      ..display = 'block'
      ..left = '${p[0]}px'
      ..top = '${p[1]}px'
      ..width = '${p[2]}px'
      ..height = '${p[3]}px';
  }

  @override
  void dispose() {
    _complete(const []);
    _ticker.dispose();
    _input?.remove();
    _input = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
