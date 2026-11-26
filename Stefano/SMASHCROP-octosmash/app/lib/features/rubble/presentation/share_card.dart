import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/links.dart';
import '../../../app/strings.dart';
import '../domain/rubble_math.dart';
import '../domain/skins.dart';

/// Crea e condivide la card "Il mio SMASH ha mangiato X kg di macerie!"
/// con la posa da eroe dello SMASH scelto (1080×1350, formato dei social).
class ShareCard {
  const ShareCard._();

  static Future<Uint8List> build(SkinDef skin, double kg) async {
    const w = 1080.0, h = 1350.0;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, const Offset(0, h), [
          const Color(0xFF0A0B10),
          Color.lerp(skin.color, Colors.black, .55)!,
        ]),
    );
    c.drawCircle(
      const Offset(w / 2, 640),
      380,
      Paint()
        ..color = skin.color.withValues(alpha: .35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120),
    );
    final data = await rootBundle.load(skin.pose);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final pose = (await codec.getNextFrame()).image;
    codec.dispose();
    c.drawImageRect(
      pose,
      Rect.fromLTWH(0, 0, pose.width.toDouble(), pose.height.toDouble()),
      const Rect.fromLTWH(140, 230, 800, 800),
      Paint()..filterQuality = FilterQuality.high,
    );
    void text(String s, double y, double size, Color color, FontWeight wt) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: size,
            fontWeight: wt,
            color: color,
            height: 1.15,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w - 140);
      tp.paint(c, Offset((w - tp.width) / 2, y));
    }

    final kgText = RubbleMath.format(kg, comma: S.decimalComma);
    text(S.eatenKg(kgText), 80, 62, Colors.white, FontWeight.w800);
    text(skin.name, 1060, 54, skin.color, FontWeight.w800);
    text('SMASHCROP', 1200, 44, Colors.white70, FontWeight.w800);
    final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    pose.dispose();
    return png!.buffer.asUint8List();
  }

  static Future<void> share(SkinDef skin, double kg, {Rect? origin}) async {
    final bytes = await build(skin, kg);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'image/png', name: 'smashcrop.png'),
        ],
        fileNameOverrides: const ['smashcrop.png'],
        text: S.shareAppText(kAppShareUrl),
        sharePositionOrigin: origin,
      ),
    );
  }
}
