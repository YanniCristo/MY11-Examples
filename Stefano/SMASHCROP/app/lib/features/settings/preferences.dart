import 'package:shared_preferences/shared_preferences.dart';

/// Preferenze leggere salvate sul dispositivo. Nessun file importato
/// finisce qui dentro.
class AppPreferences {
  AppPreferences._(this._prefs);

  static const _smashKey = 'smash_enabled';
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
}
