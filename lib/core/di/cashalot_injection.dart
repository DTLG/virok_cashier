import 'package:get_it/get_it.dart';
import '../services/cashalot_service.dart';
import '../services/mock_cashalot_service.dart';
import '../services/real_cashalot_service.dart';

final GetIt _sl = GetIt.instance;

/// Налаштування Dependency Injection для CashalotService
///
/// Для використання реальної реалізації встановіть змінну середовища
/// або змініть код нижче
void setupCashalotInjection({
  bool useReal = false,
  String? baseUrl,
  String? keyPath,
  String? certPath,
  String? keyPassword,
  String? defaultPrroFiscalNum,
}) {
  if (useReal &&
      baseUrl != null &&
      keyPath != null &&
      certPath != null &&
      keyPassword != null) {
    // Реальна реалізація з ключами
    _sl.registerLazySingleton<CashalotService>(
      () => RealCashalotService(
        baseUrl: baseUrl,
        keyPath: keyPath,
        certPath: certPath,
        keyPassword: keyPassword,
        defaultPrroFiscalNum: defaultPrroFiscalNum,
      ),
    );
  } else {
    // Mock реалізація (для розробки та тестування)
    _sl.registerLazySingleton<CashalotService>(() => MockCashalotService());
  }
}
