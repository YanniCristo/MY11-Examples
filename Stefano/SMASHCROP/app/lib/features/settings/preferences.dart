import 'package:shared_preferences/shared_preferences.dart';

import '../pdf_processing/domain/page_layout.dart';

/// Preferenze leggere salvate sul dispositivo. Nessun file importato
/// finisce qui dentro.
class AppPreferences {
  AppPreferences._(this._prefs);

  static const _smashKey = 'smash_enabled';
  static const _layoutKey = 'pdf_layout_suggestion';
  final SharedPreferences? _prefs;

  static Future<AppPreferences> load() async {
    try {
      return AppPreferences._(await SharedPreferences.getInstance());
    } catch (_) {
      return AppPreferences._(null);
    }
  }

  /// SMASH è attivo di default.
  bool get smashEnabled => _prefs?.getBool(_smashKey) ?? true;

  Future<void> setSmashEnabled(bool v) async {
    try {
      await _prefs?.setBool(_smashKey, v);
    } catch (_) {}
  }

  /// Impaginazione proposta per le pagine PDF appena tagliate: "In alto"
  /// finché l'utente non ne sceglie un'altra.
  PdfLayoutMode get layoutSuggestion {
    final name = _prefs?.getString(_layoutKey);
    return PdfLayoutMode.values.firstWhere(
      (m) => m.name == name && m != PdfLayoutMode.custom,
      orElse: () => PdfLayoutMode.top,
    );
  }

  Future<void> setLayoutSuggestion(PdfLayoutMode m) async {
    if (m == PdfLayoutMode.custom) return;
    try {
      await _prefs?.setString(_layoutKey, m.name);
    } catch (_) {}
  }
}
