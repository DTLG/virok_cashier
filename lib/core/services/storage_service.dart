import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _emailKey = 'user_email';
  static const String _passwordKey = 'user_password';
  static const String _isLoggedInKey = 'is_logged_in';

  // Ключі для Cashalot
  static const String _cashalotKeyPathKey = 'cashalot_key_path';
  static const String _cashalotCertPathKey = 'cashalot_cert_path';
  static const String _cashalotKeyPasswordKey = 'cashalot_key_password';
  static const String _cashalotSelectedPrroKey = 'cashalot_selected_prro';

  // Збереження даних користувача
  Future<void> saveUserCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Отримання email користувача
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // Отримання пароля користувача
  Future<String?> getUserPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  // Перевірка чи користувач залогінений
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Видалення даних користувача (при виході)
  Future<void> clearUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Загальні методи для роботи з налаштуваннями
  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<void> setDateTime(String key, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value.toIso8601String());
  }

  Future<DateTime?> getDateTime(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(key);
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Очищення всіх даних користувача (включаючи налаштування)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Методи для зберігання шляхів до Cashalot ключів
  Future<void> setCashalotKeyPath(String? path) async {
    if (path == null) {
      await remove(_cashalotKeyPathKey);
    } else {
      await setString(_cashalotKeyPathKey, path);
    }
  }

  Future<String?> getCashalotKeyPath() async {
    return getString(_cashalotKeyPathKey);
  }

  Future<void> setCashalotCertPath(String? path) async {
    if (path == null) {
      await remove(_cashalotCertPathKey);
    } else {
      await setString(_cashalotCertPathKey, path);
    }
  }

  Future<String?> getCashalotCertPath() async {
    return getString(_cashalotCertPathKey);
  }

  Future<void> setCashalotKeyPassword(String? password) async {
    if (password == null) {
      await remove(_cashalotKeyPasswordKey);
    } else {
      await setString(_cashalotKeyPasswordKey, password);
    }
  }

  Future<String?> getCashalotKeyPassword() async {
    return getString(_cashalotKeyPasswordKey);
  }

  Future<void> setCashalotSelectedPrro(String? prroFiscalNum) async {
    if (prroFiscalNum == null) {
      await remove(_cashalotSelectedPrroKey);
    } else {
      await setString(_cashalotSelectedPrroKey, prroFiscalNum);
    }
  }

  Future<String?> getCashalotSelectedPrro() async {
    return getString(_cashalotSelectedPrroKey);
  }
}
