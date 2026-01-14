class VchasnoConfig {
  /// Адреса локального сервера Device Manager
  static const String baseUrl = 'http://localhost:3939/dm/execute';

  /// Ваш токен з налаштувань Device Manager
  static const String token =
      "l_p__E9oUpX0k9EwoZdIZMUwAglxb4uXR_ZIl7kAEvw5aXusXeOdiYjcGwFP3OaF";

  /// Назва джерела (довільна)
  static const String source = "FlutterVirokCashier";

  /// Назва пристрою
  static const String device = "test1";

  /// Назва принтера
  static const String printerName = "testPrinter";

  static const String terminalName = "testTerminal";

  //Якщо користувач не ввів налаштування принтера, то використовуємо ці значення

  // IP-адреса мережевого принтера для RAW друку
  static const String printerIp = "192.168.1.100";

  /// Порт принтера для RAW друку (за замовчуванням 9100)
  static const int printerPort = 9100;
}
