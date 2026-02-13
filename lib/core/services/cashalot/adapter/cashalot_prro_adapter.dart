import 'package:flutter/foundation.dart';
import 'package:cash_register/core/services/prro/prro_service.dart';
import 'package:cash_register/core/models/cashalot_models.dart';
import 'package:cash_register/core/models/fiscal_result.dart';
import 'package:cash_register/core/models/x_report_data.dart';
import 'package:cash_register/core/models/vchasno_errors.dart';
import 'package:cash_register/core/models/prro_info.dart';
import 'package:cash_register/core/services/cashalot/core/cashalot_service.dart';

/// Адаптер для використання CashalotService через інтерфейс PrroService
///
/// Конвертує виклики PrroService у виклики CashalotService та адаптує відповіді
class CashalotPrroAdapter implements PrroService {
  final CashalotService _cashalotService;
  final int? _defaultPrroFiscalNum;

  CashalotPrroAdapter(this._cashalotService, {int? defaultPrroFiscalNum})
    : _defaultPrroFiscalNum = defaultPrroFiscalNum {
    debugPrint(
      '📋 [CASHALOT_ADAPTER] Ініціалізовано з defaultPrroFiscalNum: $defaultPrroFiscalNum',
    );
  }

  /// Отримує фіскальний номер ПРРО з параметра або використовує значення за замовчуванням
  int? _getPrroFiscalNum(int? prroFiscalNum) {
    final result = prroFiscalNum ?? _defaultPrroFiscalNum;
    debugPrint(
      '📋 [CASHALOT_ADAPTER] _getPrroFiscalNum: input=$prroFiscalNum, default=$_defaultPrroFiscalNum, result=$result',
    );
    return result;
  }

  @override
  Future<FiscalResult> printSale(
    CheckPayload check, {
    int? prroFiscalNum,
  }) async {
    try {
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        return FiscalResult.failure(
          message: 'Не вказано фіскальний номер ПРРО',
          error: VchasnoException(
            type: VchasnoErrorType.validationError,
            message: 'Не вказано фіскальний номер ПРРО',
          ),
        );
      }

      final response = await _cashalotService.registerSale(
        prroFiscalNum: fiscalNum,
        check: check,
      );

      if (response.isSuccess) {
        return FiscalResult.success(
          message: 'Чек успішно зареєстровано',
          qrUrl: response.qrCode,
          docNumber: response.numFiscal,
          totalAmount: check.checkTotal.sum,
        );
      } else {
        return FiscalResult.failure(
          message: response.errorMessage ?? 'Помилка реєстрації чека',
          error: VchasnoException(
            type: VchasnoErrorType.unknown,
            message: response.errorMessage ?? 'Помилка реєстрації чека',
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка printSale: $e');
      return FiscalResult.failure(
        message: e.toString(),
        error: VchasnoException(
          type: VchasnoErrorType.unknown,
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<CashalotResponse> openShift({int? prroFiscalNum}) async {
    try {
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        debugPrint('❌ [CASHALOT_ADAPTER] Не вказано фіскальний номер ПРРО');
        return CashalotResponse(
          errorCode: 'ERROR',
          errorMessage: 'Не вказано фіскальний номер ПРРО',
        );
      }

      final response = await _cashalotService.openShift(
        prroFiscalNum: fiscalNum,
      );
      return response;
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка openShift: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  @override
  Future<XReportData?> printXReport({int? prroFiscalNum}) async {
    try {
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        debugPrint('❌ [CASHALOT_ADAPTER] Не вказано фіскальний номер ПРРО');
        return null;
      }

      final response = await _cashalotService.printXReport(
        prroFiscalNum: fiscalNum,
      );
      if (!response.isSuccess) {
        debugPrint(
          '❌ [CASHALOT_ADAPTER] Помилка printXReport: ${response.errorMessage}',
        );
        return null;
      }

      return XReportData(
        task: 10,
        visualization: response.visualization,
        isZRep: false,
        shiftOpened: response.shiftOpened,
        serviceInput: response.serviceInput,
        serviceOutput: response.serviceOutput,
      );
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка printXReport: $e');
      return null;
    }
  }

  @override
  Future<XReportData?> closeShift({int? prroFiscalNum}) async {
    try {
      debugPrint(
        '🔒 [CASHALOT_ADAPTER] closeShift: prroFiscalNum=$prroFiscalNum',
      );
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        debugPrint(
          '❌ [CASHALOT_ADAPTER] Не вказано фіскальний номер ПРРО (closeShift)',
        );
        return null;
      }

      debugPrint(
        '🔒 [CASHALOT_ADAPTER] Виклик closeShift з fiscalNum=$fiscalNum',
      );

      final response = await _cashalotService.closeShift(
        prroFiscalNum: fiscalNum,
      );

      if (!response.isSuccess) {
        debugPrint(
          '❌ [CASHALOT_ADAPTER] Помилка closeShift: ${response.errorMessage}',
        );
        return null;
      }
      return XReportData(
        task: 11,
        visualization: response.visualization,
        isZRep: true,
      );
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка closeShift: $e');
      return null;
    }
  }

  @override
  Future<List<PrroInfo>> getAvailablePrrosInfo() async {
    return await _cashalotService.getAvailablePrrosInfo();
  }

  @override
  Future<XReportData?> serviceIn(
    double amount, {
    required String cashier,
    int? prroFiscalNum,
  }) async {
    try {
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        throw Exception('Не вказано фіскальний номер ПРРО');
      }

      final response = await _cashalotService.serviceDeposit(
        prroFiscalNum: fiscalNum,
        amount: amount,
        cashier: cashier,
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Помилка службового внесення');
      }
      return XReportData(visualization: response.visualization);
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка serviceIn: $e');
      rethrow;
    }
  }

  @override
  Future<XReportData?> serviceOut(
    double amount, {
    required String cashier,
    int? prroFiscalNum,
  }) async {
    try {
      debugPrint(
        '💸 [CASHALOT_ADAPTER] serviceOut: amount=$amount, cashier=$cashier, prroFiscalNum=$prroFiscalNum',
      );
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        throw Exception('Не вказано фіскальний номер ПРРО (serviceOut)');
      }

      debugPrint(
        '💸 [CASHALOT_ADAPTER] Виклик serviceIssue з fiscalNum=$fiscalNum',
      );

      final response = await _cashalotService.serviceIssue(
        prroFiscalNum: fiscalNum,
        amount: amount,
        cashier: cashier,
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Помилка службової видачі');
      }
      return XReportData(visualization: response.visualization);
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка serviceOut: $e');
      rethrow;
    }
  }

  @override
  Future<XReportData> cleanupCashalot({int? prroFiscalNum}) async {
    final response = await _cashalotService.cleanupCashalot(
      prroFiscalNum: prroFiscalNum ?? _defaultPrroFiscalNum!,
    );
    return XReportData(visualization: response.visualization);
  }
}
