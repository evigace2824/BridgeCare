import 'package:shared_preferences/shared_preferences.dart';

/// Persists “Remember me” (email only; never the password).
class AuthRememberPrefs {
  AuthRememberPrefs._();

  static const _keyEmail = 'carebridge_remembered_email';
  static const _keyRemember = 'carebridge_remember_me';

  static Future<bool> loadRememberFlag() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyRemember) ?? false;
  }

  static Future<String?> loadRememberedEmail() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyEmail);
  }

  static Future<void> applyRememberChoice({
    required String email,
    required bool rememberMe,
  }) async {
    final p = await SharedPreferences.getInstance();
    if (rememberMe) {
      await p.setBool(_keyRemember, true);
      await p.setString(_keyEmail, email.trim());
    } else {
      await p.setBool(_keyRemember, false);
      await p.remove(_keyEmail);
    }
  }
}
