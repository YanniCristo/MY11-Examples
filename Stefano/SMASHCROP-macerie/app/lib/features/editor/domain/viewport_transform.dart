import 'dart:math' as math;
import 'dart:ui';

import 'cut_operation.dart';

/// Margini del viewport riservati alle maniglie A/B.
///
/// Le maniglie stanno fuori dall'immagine, quindi il margine largo serve solo
/// sull'asse dove si trovano: ai lati per il taglio orizzontale, sopra e
/// sotto per quello verticale.
class Gutters {
  const Gutters(this.left, this.top, this.right, this.bottom);

  static const double handle = 34;
  static const double base = 8;

  factory Gutters.forOrientation(CutOrientation o) =>
      o == CutOrientation.horizontal
      ? const Gutters(handle, base, handle, base)
      : const Gutters(base, handle, base, handle);

  final double left, top, right, bottom;
}

/// Conversione tra coordinate del documento (pixel) e coordinate del viewport.
///
/// Zoom 1.0 significa "documento intero adattato al viewport", non un pixel
/// per punto. Lo spostamento ([pan]) è relativo alla posizione centrata.
class ViewportTransform {
  const ViewportTransform({
    required this.viewport,
    required this.content,
    required this.gutters,
    this.zoom = 1,
    this.pan = Offset.zero,
  });

  static const double minZoom = 1;
  static const double maxZoom = 5;

  final Size viewport;
  final Size content;
  final Gutters gutters;
  final double zoom;
  final Offset pan;

  Rect get fitArea => Rect.fromLTRB(
    gutters.left,
    gutters.top,
    viewport.width - gutters.right,
    viewport.height - gutters.bottom,
  );

  double get fitScale {
    if (content.isEmpty || viewport.isEmpty) return 1;
    final a = fitArea;
    return math.max(
      0.0001,
      math.min(a.width / content.width, a.height / content.height),
    );
  }

  double get scale => fitScale * zoom;

  Rect get contentRect {
    final a = fitArea;
    final w = content.width * scale;
    final h = content.height * scale;
    return Rect.fromLTWH(
      a.center.dx - w / 2 + pan.dx,
      a.center.dy - h / 2 + pan.dy,
      w,
      h,
    );
  }

  Offset contentToScreen(Offset p) => contentRect.topLeft + p * scale;
  Offset screenToContent(Offset s) => (s - contentRect.topLeft) / scale;

  /// Rettangolo a schermo di una regione del documento.
  Rect regionToScreen(Rect r) {
    final o = contentRect.topLeft;
    return Rect.fromLTWH(
      o.dx + r.left * scale,
      o.dy + r.top * scale,
      r.width * scale,
      r.height * scale,
    );
  }

  ViewportTransform copyWith({
    Size? viewport,
    Size? content,
    Gutters? gutters,
    double? zoom,
    Offset? pan,
  }) => ViewportTransform(
    viewport: viewport ?? this.viewport,
    content: content ?? this.content,
    gutters: gutters ?? this.gutters,
    zoom: zoom ?? this.zoom,
    pan: pan ?? this.pan,
  ).clamped();

  /// Tiene il documento dentro l'area utile: centrato se più piccolo,
  /// senza bordi vuoti se più grande.
  ViewportTransform clamped() {
    final z = zoom.clamp(minZoom, maxZoom).toDouble();
    final a = fitArea;
    final s = fitScale * z;
    final w = content.width * s;
    final h = content.height * s;
    final mx = math.max(0.0, (w - a.width) / 2);
    final my = math.max(0.0, (h - a.height) / 2);
    final p = Offset(
      pan.dx.clamp(-mx, mx).toDouble(),
      pan.dy.clamp(-my, my).toDouble(),
    );
    if (z == zoom && p == pan) return this;
    return ViewportTransform(
      viewport: viewport,
      content: content,
      gutters: gutters,
      zoom: z,
      pan: p,
    );
  }

  /// Zoom mantenendo fermo sotto [focal] il punto del documento che c'era.
  ViewportTransform zoomedAround(Offset focal, double newZoom) {
    final anchor = screenToContent(focal);
    final z = newZoom.clamp(minZoom, maxZoom).toDouble();
    final next = ViewportTransform(
      viewport: viewport,
      content: content,
      gutters: gutters,
      zoom: z,
      pan: pan,
    );
    final drift = focal - next.contentToScreen(anchor);
    return next.copyWith(pan: pan + drift);
  }

  ViewportTransform panned(Offset delta) => copyWith(pan: pan + delta);
}
