import 'package:shared_preferences/shared_preferences.dart';

import '../../app/strings.dart';
import '../pdf_processing/domain/page_layout.dart';

/// Preferenze leggere salvate sul dispositivo. Nessun file importato
/// finisce qui dentro: del lavoro in corso si tengono solo nome e peso del
/// file e le coordinate dei tagli (la copia del file è in `WorkFileStore`).
class AppPreferences {
  AppPreferences._(this._prefs);

  static const _smashKey = 'smash_enabled';
  static const _layoutKey = 'pdf_layout_suggestion';
  static const _workKey = 'saved_work';
  static const _langKey = 'language';
  static const _fineHintKey = 'fine_hint_shown';
  final SharedPreferences? _prefs;

  static Future<AppPreferences> load() async {
    try {
      return AppPreferences._(await SharedPreferences.getInstance());
    } catch (_) {
      return AppPreferences._(null);
    }
  }

  /// Il suggerimento sulla precisione al pixel è già stato mostrato.
  bool get fineHintShown => _prefs?.getBool(_fineHintKey) ?? false;

  Future<void> setFineHintShown() async {
    try {
      await _prefs?.setBool(_fineHintKey, true);
    } catch (_) {}
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

  /// Lavoro in corso (JSON di SavedWork), `null` se non c'è.
  String? get savedWork => _prefs?.getString(_workKey);

  Future<void> setSavedWork(String json) async {
    try {
      await _prefs?.setString(_workKey, json);
    } catch (_) {}
  }

  Future<void> clearSavedWork() async {
    try {
      await _prefs?.remove(_workKey);
    } catch (_) {}
  }

  /// Lingua scelta dall'utente; `null` = automatica (lingua del dispositivo).
  AppLang? get language => AppLang.fromCode(_prefs?.getString(_langKey));

  Future<void> setLanguage(AppLang? l) async {
    try {
      if (l == null) {
        await _prefs?.remove(_langKey);
      } else {
        await _prefs?.setString(_langKey, l.name);
      }
    } catch (_) {}
  }

  /// Applica la lingua: quella scelta, oppure quella del dispositivo
  /// (inglese se non è tra le sei dell'app o non si riesce a leggerla).
  void applyLanguage() => S.current.value = language ?? AppLang.device();
}
