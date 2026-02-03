import 'package:flutter/foundation.dart';
import 'cashalot_service.dart';
import 'prro_service.dart';
import '../models/cashalot_models.dart';
import '../../services/fiscal_result.dart';
import '../../services/x_report_data.dart';
import '../../services/vchasno_errors.dart';
import '../models/prro_info.dart';

/// Адаптер для використання CashalotService через інтерфейс PrroService
///
/// Конвертує виклики PrroService у виклики CashalotService та адаптує відповіді
class CashalotPrroAdapter implements PrroService {
  final CashalotService _cashalotService;
  final int? _defaultPrroFiscalNum;

  CashalotPrroAdapter(this._cashalotService, {int? defaultPrroFiscalNum})
    : _defaultPrroFiscalNum = defaultPrroFiscalNum;

  /// Отримує фіскальний номер ПРРО з параметра або використовує значення за замовчуванням
  int? _getPrroFiscalNum(int? prroFiscalNum) {
    return prroFiscalNum ?? _defaultPrroFiscalNum;
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
  Future<bool> openShift({int? prroFiscalNum}) async {
    try {
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        debugPrint('❌ [CASHALOT_ADAPTER] Не вказано фіскальний номер ПРРО');
        return false;
      }

      final response = await _cashalotService.openShift(
        prroFiscalNum: fiscalNum,
      );
      return response.isSuccess;
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка openShift: $e');
      return false;
    }
  }

  @override
  Future<XReportData?> closeShift({int? prroFiscalNum}) async {
    try {
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        debugPrint('❌ [CASHALOT_ADAPTER] Не вказано фіскальний номер ПРРО');
        return null;
      }

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
  Future<XReportData?> printXReport({int? prroFiscalNum}) async {
    // CashalotService не має методу для X-звіту
    // Можна буде додати якщо потрібно
    debugPrint(
      '⚠️ [CASHALOT_ADAPTER] printXReport не реалізовано для CashalotService',
    );
    return null;
  }

  @override
  Future<void> serviceIn(
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
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка serviceIn: $e');
      rethrow;
    }
  }

  @override
  Future<void> serviceOut(
    double amount, {
    required String cashier,
    int? prroFiscalNum,
  }) async {
    try {
      final fiscalNum = _getPrroFiscalNum(prroFiscalNum);
      if (fiscalNum == null) {
        throw Exception('Не вказано фіскальний номер ПРРО');
      }

      final response = await _cashalotService.serviceIssue(
        prroFiscalNum: fiscalNum,
        amount: amount,
        cashier: cashier,
      );

      if (!response.isSuccess) {
        throw Exception(response.errorMessage ?? 'Помилка службової видачі');
      }
    } catch (e) {
      debugPrint('❌ [CASHALOT_ADAPTER] Помилка serviceOut: $e');
      rethrow;
    }
  }
}
