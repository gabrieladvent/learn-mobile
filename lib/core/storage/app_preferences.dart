import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_preferences.g.dart';

class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _introSeenKey = 'intro_seen';

  Future<bool> hasSeenIntro() async {
    return await _prefs.getBool(_introSeenKey) ?? false;
  }

  Future<void> markIntroSeen() => _prefs.setBool(_introSeenKey, true);
}

@Riverpod(keepAlive: true)
AppPreferences appPreferences(Ref ref) {
  return AppPreferences(SharedPreferencesAsync());
}
