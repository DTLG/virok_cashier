import '../models/cashalot_models.dart';
import '../models/prro_info.dart';
import '../models/pos_result.dart';

/// Абстрактний інтерфейс для роботи з Cashalot API
/// Визначає контракт для всіх реалізацій (Mock та Real)
abstract class CashalotService {
  /// Перевірка доступних кас (ПРРО)
  /// Повертає список фіскальних номерів доступних ПРРО
  @Deprecated(
    'Використовуйте getAvailablePrrosInfo() для отримання повної інформації',
  )
  Future<List<PrroInfo>> getAvailablePrros();

  /// Отримання списку доступних ПРРО з повною інформацією
  /// Повертає список PrroInfo з назвами та номерами кас
  Future<List<PrroInfo>> getAvailablePrrosInfo();

  /// Отримання стану ПРРО (TransactionsRegistrarState)
  /// Обов'язковий виклик перед будь-якими операціями
  /// Повертає стан зміни: shiftState = 0 (закрита) або 1 (відкрита)
  Future<CashalotResponse> getPrroState({required int prroFiscalNum});

  /// Відкриття зміни
  /// [prroFiscalNum] - фіскальний номер ПРРО
  Future<CashalotResponse> openShift({required int prroFiscalNum});

  /// Реєстрація продажу (звичайний чек)
  /// [prroFiscalNum] - фіскальний номер ПРРО
  /// [check] - дані чека для реєстрації
  Future<CashalotResponse> registerSale({
    required int prroFiscalNum,
    required CheckPayload check,
    PosTransactionResult? cardData,
  });

  /// Службове внесення грошей (розмін)
  /// [prroFiscalNum] - фіскальний номер ПРРО
  /// [amount] - сума для внесення
  /// [cashier] - ім'я касира
  Future<CashalotResponse> serviceDeposit({
    required int prroFiscalNum,
    required double amount,
    required String cashier,
  });

  Future<PrroInfo> getPrroInfo({required int prroFiscalNum});

  /// Службова видача грошей (інкасація)
  /// [prroFiscalNum] - фіскальний номер ПРРО
  /// [amount] - сума для видачі
  /// [cashier] - ім'я касира
  Future<CashalotResponse> serviceIssue({
    required int prroFiscalNum,
    required double amount,
    required String cashier,
  });

  /// Закриття зміни (Z-звіт)
  /// [prroFiscalNum] - фіскальний номер ПРРО
  Future<CashalotResponse> closeShift({required int prroFiscalNum});

  /// Отримання X-звіту (поточний стан)

  Future<CashalotResponse> printXReport({required int prroFiscalNum});
  Future<CashalotResponse> cleanupCashalot({required int prroFiscalNum});
}
