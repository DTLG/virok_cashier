import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:cash_register/core/services/prro/prro_service.dart';
import 'package:cash_register/core/services/prro/vchasno_service.dart';
import 'package:cash_register/core/services/cashalot/core/cashalot_service.dart';
import 'package:cash_register/core/services/cashalot/adapter/cashalot_prro_adapter.dart';
import 'package:cash_register/core/services/cashalot/com/cashalot_com_service.dart';

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
  debugPrint(
    '📋 [PRRO_INJECTION] Налаштування PrroService: type=$serviceType, defaultPrroFiscalNum=$defaultPrroFiscalNum',
  );

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
      // Реєстрація CashalotComService як PrroService через адаптер
      if (!_sl.isRegistered<CashalotComService>()) {
        _sl.registerLazySingleton<CashalotComService>(() => CashalotComService());
      }

      _sl.registerLazySingleton<PrroService>(
        () => CashalotPrroAdapter(
          _sl<CashalotComService>(),
          defaultPrroFiscalNum: defaultPrroFiscalNum,
        ),
      );
      break;
  }
}
