import 'package:get_it/get_it.dart';
import '../services/prro_service.dart';
import '../../services/vchasno_service.dart';
import '../services/cashalot_service.dart';
import '../services/cashalot_prro_adapter.dart';
import '../services/cashalot_com_service.dart';

final GetIt _sl = GetIt.instance;

/// Тип ПРРО сервісу для використання
enum PrroServiceType { vchasno, cashalot, cashalotCom }

/// Налаштування Dependency Injection для PrroService
///
/// Дозволяє легко перемикатися між різними реалізаціями ПРРО
///
/// [serviceType] - тип сервісу для використання (Vchasno або Cashalot)
/// [defaultPrroFiscalNum] - фіскальний номер ПРРО за замовчуванням (для Cashalot)
void setupPrroInjection({
  PrroServiceType serviceType = PrroServiceType.vchasno,
  int? defaultPrroFiscalNum,
}) {
  switch (serviceType) {
    case PrroServiceType.vchasno:
      // Реєстрація VchasnoService як PrroService
      _sl.registerLazySingleton<PrroService>(() => VchasnoService());
      break;

    case PrroServiceType.cashalot:
      // Реєстрація CashalotService через адаптер як PrroService
      // Перед цим повинен бути зареєстрований CashalotService
      if (!_sl.isRegistered<CashalotService>()) {
        throw Exception(
          'CashalotService повинен бути зареєстрований перед PrroService',
        );
      }
      _sl.registerLazySingleton<PrroService>(
        () => CashalotPrroAdapter(
          _sl<CashalotService>(),
          defaultPrroFiscalNum: defaultPrroFiscalNum,
        ),
      );
      break;

    case PrroServiceType.cashalotCom:
      // Реєстрація CashalotComService як PrroService
      _sl.registerLazySingleton<PrroService>(
        () => CashalotPrroAdapter(
          _sl<CashalotComService>(),
          defaultPrroFiscalNum: defaultPrroFiscalNum,
        ),
      );
      break;
  }
}
