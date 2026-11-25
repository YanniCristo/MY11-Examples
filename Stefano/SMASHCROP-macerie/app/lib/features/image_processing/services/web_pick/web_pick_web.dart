import 'dart:async';
import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

/// Scelta delle immagini nel browser con un campo file nostro.
///
/// Su iPhone Safari il menu "Libreria foto / Scatta foto / Scegli file"
/// nasce dal campo file: se il campo è nascosto (`display: none`, come fanno
/// i pacchetti) Safari non sa dov'è e fa comparire un grosso cerchio bianco
/// in mezzo allo schermo. Qui il campo è invisibile ma sta proprio sotto il
/// dito, così il menu nasce dal pulsante toccato.
double _x = 0, _y = 0;
bool _watching = false;

/// Tiene a mente dove l'utente ha toccato per ultimo.
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

Future<List<XFile>> pickImagesWeb() {
  final done = Completer<List<XFile>>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = true
    ..accept = 'image/*';
  const size = 48;
  input.style
    ..position = 'fixed'
    ..left = '${(_x - size / 2).round()}px'
    ..top = '${(_y - size / 2).round()}px'
    ..width = '${size}px'
    ..height = '${size}px'
    ..opacity = '0'
    ..pointerEvents = 'none'
    ..zIndex = '-1';

  void finish(List<XFile> files) {
    if (done.isCompleted) return;
    done.complete(files);
    // lo si toglie dopo un attimo: Safari finisce prima di leggere i file
    Timer(const Duration(seconds: 1), () => input.remove());
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final list = input.files;
      final out = <XFile>[];
      if (list != null) {
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
      }
      finish(out);
    }).toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => finish(const [])).toJS);
  web.document.body?.append(input);
  input.click();
  return done.future;
}
