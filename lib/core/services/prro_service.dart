import '../models/cashalot_models.dart';
import '../../services/fiscal_result.dart';
import '../../services/x_report_data.dart';
import '../models/prro_info.dart';

/// Спільний інтерфейс для роботи з будь-яким ПРРО (Програмно-Реалізований Реєстратор Операцій)
///
/// Цей інтерфейс дозволяє легко перемикатися між різними реалізаціями ПРРО
/// (VchasnoService, CashalotService тощо) через Dependency Injection
abstract class PrroService {
  /// Отримання списку доступних ПРРО з повною інформацією
  /// Повертає список PrroInfo з назвами та номерами кас
  Future<List<PrroInfo>> getAvailablePrrosInfo();

  /// Реєстрація продажу (звичайний чек)
  ///
  /// [check] - дані чека для реєстрації
  /// [prroFiscalNum] - фіскальний номер ПРРО (опціонально, для сервісів що потребують)
  ///
  /// Повертає [FiscalResult] з результатом операції
  Future<FiscalResult> printSale(CheckPayload check, {int? prroFiscalNum});

  /// Відкриття зміни
  ///
  /// [prroFiscalNum] - фіскальний номер ПРРО (опціонально, для сервісів що потребують)
  ///
  /// Повертає true якщо зміна успішно відкрита
  Future<bool> openShift({int? prroFiscalNum});

  /// Закриття зміни (Z-звіт)
  ///
  /// [prroFiscalNum] - фіскальний номер ПРРО (опціонально, для сервісів що потребують)
  ///
  /// Повертає дані Z-звіту або null якщо не вдалося закрити зміну
  Future<XReportData?> closeShift({int? prroFiscalNum});

  /// Отримання X-звіту (поточний стан)
  ///
  /// [prroFiscalNum] - фіскальний номер ПРРО (опціонально, для сервісів що потребують)
  ///
  /// Повертає дані X-звіту або null якщо не вдалося отримати звіт
  Future<XReportData?> printXReport({int? prroFiscalNum});

  /// Службове внесення грошей (розмін)
  ///
  /// [amount] - сума для внесення
  /// [cashier] - ім'я касира
  /// [prroFiscalNum] - фіскальний номер ПРРО (опціонально, для сервісів що потребують)
  Future<void> serviceIn(
    double amount, {
    required String cashier,
    int? prroFiscalNum,
  });

  /// Службова видача грошей (інкасація)
  ///
  /// [amount] - сума для видачі
  /// [cashier] - ім'я касира
  /// [prroFiscalNum] - фіскальний номер ПРРО (опціонально, для сервісів що потребують)
  Future<void> serviceOut(
    double amount, {
    required String cashier,
    int? prroFiscalNum,
  });
}
