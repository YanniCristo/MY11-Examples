import 'package:material_ui/material_ui.dart';

/// Colori presi dalle interfacce approvate: fondo quasi nero, pulsanti
/// antracite, rosso come colore delle azioni e della selezione.
class AppColors {
  const AppColors._();

  static const background = Color(0xFF0A0B10);
  static const surface = Color(0xFF14161C);
  static const button = Color(0xFF1F222A);
  static const buttonPressed = Color(0xFF2A2E37);
  static const border = Color(0xFF2E323B);
  static const text = Color(0xFFF3F4F6);
  static const textMuted = Color(0xFF9CA3AF);
  static const red = Color(0xFFE5172F);
  static const redLight = Color(0xFFFF3348);
  static const redDark = Color(0xFFB80D20);
  static const neonPink = Color(0xFFFF2BD6);
  static const neonViolet = Color(0xFF8B5CF6);
  static const viewport = Color(0xFF06070A);
  static const selectionShade = Color(0x6B000000);
}

const String kDisplayFont = 'Poppins';

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.red,
      onPrimary: Colors.white,
      secondary: AppColors.red,
      surface: AppColors.surface,
      onSurface: AppColors.text,
    ),
  );
  return base.copyWith(
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.button,
      contentTextStyle: TextStyle(color: AppColors.text, fontSize: 15),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.red,
      inactiveTrackColor: Color(0xFF3A3E47),
      thumbColor: AppColors.red,
      overlayColor: Color(0x33E5172F),
      trackHeight: 4,
    ),
  );
}
