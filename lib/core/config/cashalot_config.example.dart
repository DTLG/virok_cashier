/// Приклад конфігураційного файлу для Cashalot
///
/// ІНСТРУКЦІЯ:
/// 1. Скопіюйте цей файл в `cashalot_config.dart`
/// 2. Заповніть реальними значеннями
/// 3. Файл `cashalot_config.dart` вже додано в .gitignore і не буде закомічений
///
/// ⚠️ НЕ КОМІТЬТЕ ФАЙЛ `cashalot_config.dart` В GIT!

class CashalotConfig {
  /// Базовий URL API Cashalot
  static const String baseUrl = 'https://fsapi.cashalot.org.ua';

  /// Шлях до приватного ключа в assets
  /// Приклад: 'assets/cashalot_keys/Key-6.dat' або 'assets/keys/Key-6.dat'
  static const String keyPath = 'assets/cashalot_keys/Key-6.dat';

  /// Шлях до сертифіката в assets
  /// Приклад: 'assets/cashalot_keys/Cert.crt' або 'assets/keys/Cert.crt'
  static const String certPath = 'assets/cashalot_keys/Cert.crt';

  /// Пароль від приватного ключа
  /// ⚠️ НЕ КОМІТЬТЕ ЦЕ ЗНАЧЕННЯ В GIT!
  static const String keyPassword = 'ВАШ_ПАРОЛЬ_ВІД_КЛЮЧА';

  /// Фіскальний номер ПРРО за замовчуванням
  static const String defaultPrroFiscalNum = '4000000001';

  /// Чи використовувати реальний API (true) або Mock (false)
  static const bool useReal = false;
}
