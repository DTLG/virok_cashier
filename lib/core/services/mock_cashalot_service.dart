import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/cashalot_models.dart';
import '../models/prro_info.dart';
import '../models/pos_result.dart';
import 'cashalot_service.dart';

/// Mock реалізація CashalotService
/// Імітує роботу з API без реальних запитів
/// Використовується для розробки та тестування
class MockCashalotService implements CashalotService {
  // Імітуємо затримку мережі
  Future<void> _fakeNetworkDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<PrroInfo>> getAvailablePrros() async {
    debugPrint('📡 [CASHALOT] Запит: getAvailablePrros()');
    await _fakeNetworkDelay();
    // Повертаємо фейкові ПРРО з інформацією
    final result = [
      PrroInfo(numFiscal: '4000000001', name: 'Каса 1 (Mock)'),
      PrroInfo(numFiscal: '4000000002', name: 'Каса 2 (Mock)'),
    ];
    debugPrint('📥 [CASHALOT] Відповідь getAvailablePrros: $result');
    return result;
  }

  @override
  Future<List<PrroInfo>> getAvailablePrrosInfo() async {
    debugPrint('📡 [CASHALOT] Запит: getAvailablePrrosInfo()');
    await _fakeNetworkDelay();
    // Повертаємо фейкові ПРРО з інформацією
    final result = [
      PrroInfo(
        numFiscal: '4000000001',
        name: 'Каса 1 (Mock)',
        address: 'Тестова адреса 1',
      ),
      PrroInfo(
        numFiscal: '4000000002',
        name: 'Каса 2 (Mock)',
        address: 'Тестова адреса 2',
      ),
    ];
    debugPrint(
      '📥 [CASHALOT] Відповідь getAvailablePrrosInfo: ${result.length} кас',
    );
    return result;
  }

  @override
  Future<CashalotResponse> getPrroState({required int prroFiscalNum}) async {
    debugPrint('📡 [CASHALOT] Запит: getPrroState()');
    debugPrint('   ПРРО: $prroFiscalNum');
    await _fakeNetworkDelay();

    // Імітуємо стан: 0 - закрита, 1 - відкрита
    // Для тестування завжди повертаємо закриту зміну
    final shiftState = 0;
    debugPrint('📊 [CASHALOT] Стан зміни (ShiftState): $shiftState');
    debugPrint('   ⚠️ Зміна закрита (Mock)');

    final response = CashalotResponse(
      shiftState: shiftState,
      errorCode: null, // Успіх
    );

    debugPrint('📥 [CASHALOT] Відповідь getPrroState:');
    debugPrint('   Успіх: true');
    debugPrint('   ShiftState: $shiftState');

    return response;
  }

  @override
  Future<CashalotResponse> openShift({required int prroFiscalNum}) async {
    debugPrint('📡 [CASHALOT] Запит: openShift()');
    debugPrint('   Параметри:');
    debugPrint('     prroFiscalNum: $prroFiscalNum');
    await _fakeNetworkDelay();

    final fiscalNum = "SHIFT_${DateTime.now().millisecondsSinceEpoch}";
    final response = CashalotResponse(
      numFiscal: fiscalNum,
      errorCode: null, // Успіх
    );

    debugPrint('📥 [CASHALOT] Відповідь openShift:');
    debugPrint('   Успіх: true');
    debugPrint('   Фіскальний номер: $fiscalNum');
    debugPrint('✅ [CASHALOT] Зміна відкрита для ПРРО $prroFiscalNum');

    return response;
  }

  @override
  Future<CashalotResponse> registerSale({
    required int prroFiscalNum,
    required CheckPayload check,
    PosTransactionResult? cardData,
  }) async {
    debugPrint('📡 [CASHALOT] Запит: registerSale()');
    debugPrint('   Параметри:');
    debugPrint('     prroFiscalNum: $prroFiscalNum');
    debugPrint('   Тіло запиту (CheckPayload):');
    debugPrint('     Касир: ${check.checkHead.cashier}');
    debugPrint(
      '     Тип: ${check.checkHead.docType} / ${check.checkHead.docSubType}',
    );
    debugPrint('     Сума: ${check.checkTotal.sum} UAH');
    debugPrint('     Товарів: ${check.checkBody.length}');
    debugPrint(
      '     Метод оплати: ${check.checkPay.map((p) => '${p.payFormNm} ${p.sum}').join(', ')}',
    );
    debugPrint('   JSON тіло:');
    debugPrint(const JsonEncoder.withIndent('     ').convert(check.toJson()));

    await _fakeNetworkDelay();

    final fiscalNum = "CHK_${DateTime.now().millisecondsSinceEpoch}";
    final visualization = _buildReceiptVisualization(check, fiscalNum);

    final response = CashalotResponse(
      numFiscal: fiscalNum,
      // Тут можна вставити реальну Base64 стрінгу якоїсь картинки для тесту UI
      qrCode:
          "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
      // Візуалізація для друку
      visualization: visualization,
    );

    debugPrint('📥 [CASHALOT] Відповідь registerSale:');
    debugPrint('   Успіх: true');
    debugPrint('   Фіскальний номер: $fiscalNum');
    debugPrint('   QR код присутній: ${response.qrCode != null}');
    debugPrint('   Візуалізація присутня: ${response.visualization != null}');
    debugPrint(
      '✅ [CASHALOT] Чек продажу зареєстровано. ПРРО: $prroFiscalNum, Сума: ${check.checkTotal.sum}',
    );

    return response;
  }

  @override
  Future<CashalotResponse> serviceDeposit({
    required int prroFiscalNum,
    required double amount,
    required String cashier,
  }) async {
    debugPrint('📡 [CASHALOT] Запит: serviceDeposit()');
    debugPrint('   Параметри:');
    debugPrint('     prroFiscalNum: $prroFiscalNum');
    debugPrint('     amount: $amount UAH');
    debugPrint('     cashier: $cashier');

    await _fakeNetworkDelay();

    final fiscalNum = "DEP_${DateTime.now().millisecondsSinceEpoch}";
    final visualization = _buildServiceDepositVisualization(
      amount,
      cashier,
      fiscalNum,
    );
    final response = CashalotResponse(
      numFiscal: fiscalNum,
      visualization: visualization,
    );

    debugPrint('📥 [CASHALOT] Відповідь serviceDeposit:');
    debugPrint('   Успіх: true');
    debugPrint('   Фіскальний номер: $fiscalNum');
    debugPrint(
      '✅ [CASHALOT] Службове внесення: $amount UAH для ПРРО $prroFiscalNum',
    );

    return response;
  }

  @override
  Future<CashalotResponse> serviceIssue({
    required int prroFiscalNum,
    required double amount,
    required String cashier,
  }) async {
    debugPrint('📡 [CASHALOT] Запит: serviceIssue()');
    debugPrint('   Параметри:');
    debugPrint('     prroFiscalNum: $prroFiscalNum');
    debugPrint('     amount: $amount UAH');
    debugPrint('     cashier: $cashier');

    await _fakeNetworkDelay();

    final fiscalNum = "ISS_${DateTime.now().millisecondsSinceEpoch}";
    final visualization = _buildServiceIssueVisualization(
      amount,
      cashier,
      fiscalNum,
    );
    final response = CashalotResponse(
      numFiscal: fiscalNum,
      visualization: visualization,
    );

    debugPrint('📥 [CASHALOT] Відповідь serviceIssue:');
    debugPrint('   Успіх: true');
    debugPrint('   Фіскальний номер: $fiscalNum');
    debugPrint(
      '✅ [CASHALOT] Службова видача: $amount UAH для ПРРО $prroFiscalNum',
    );

    return response;
  }

  @override
  Future<CashalotResponse> closeShift({required int prroFiscalNum}) async {
    debugPrint('📡 [CASHALOT] Запит: closeShift()');
    debugPrint('   Параметри:');
    debugPrint('     prroFiscalNum: $prroFiscalNum');

    await _fakeNetworkDelay();

    final fiscalNum = "ZREP_${DateTime.now().millisecondsSinceEpoch}";
    final visualization = _buildZReportVisualization(fiscalNum);
    final response = CashalotResponse(
      numFiscal: fiscalNum,
      visualization: visualization,
    );

    debugPrint('📥 [CASHALOT] Відповідь closeShift:');
    debugPrint('   Успіх: true');
    debugPrint('   Фіскальний номер: $fiscalNum');
    debugPrint('   Візуалізація присутня: ${response.visualization != null}');
    debugPrint(
      '✅ [CASHALOT] Зміна закрита для ПРРО $prroFiscalNum. Z-звіт сформовано.',
    );

    return response;
  }

  @override
  Future<CashalotResponse> cleanupCashalot({required int prroFiscalNum}) async {
    return CashalotResponse(errorCode: 'SUCCESS');
  }

  /// Формує текстовий вигляд чека продажу
  String _buildReceiptVisualization(CheckPayload check, String fiscalNum) {
    final buffer = StringBuffer();
    buffer.writeln("--------------------------------");
    buffer.writeln("ФІСКАЛЬНИЙ ЧЕК");
    buffer.writeln("Касир: ${check.checkHead.cashier}");
    buffer.writeln("--------------------------------");
    buffer.writeln("ТОВАРИ:");
    for (final item in check.checkBody) {
      buffer.writeln(
        "  ${item.name} x${item.amount} = ${item.cost.toStringAsFixed(2)} UAH",
      );
    }
    buffer.writeln("--------------------------------");
    buffer.writeln("ВСЬОГО: ${check.checkTotal.sum.toStringAsFixed(2)} UAH");
    buffer.writeln(
      "Оплата: ${check.checkPay.map((p) => '${p.payFormNm} ${p.sum.toStringAsFixed(2)}').join(', ')}",
    );
    buffer.writeln("--------------------------------");
    buffer.writeln("ФН чека: $fiscalNum");
    buffer.writeln("Дата: ${DateTime.now().toString().substring(0, 19)}");
    buffer.writeln("--------------------------------");
    return buffer.toString();
  }

  /// Формує текстовий вигляд службового внесення
  String _buildServiceDepositVisualization(
    double amount,
    String cashier,
    String fiscalNum,
  ) {
    final buffer = StringBuffer();
    buffer.writeln("--------------------------------");
    buffer.writeln("СЛУЖБОВЕ ВНЕСЕННЯ");
    buffer.writeln("Касир: $cashier");
    buffer.writeln("--------------------------------");
    buffer.writeln("Сума: ${amount.toStringAsFixed(2)} UAH");
    buffer.writeln("--------------------------------");
    buffer.writeln("ФН документа: $fiscalNum");
    buffer.writeln("Дата: ${DateTime.now().toString().substring(0, 19)}");
    buffer.writeln("--------------------------------");
    return buffer.toString();
  }

  /// Формує текстовий вигляд службової видачі
  String _buildServiceIssueVisualization(
    double amount,
    String cashier,
    String fiscalNum,
  ) {
    final buffer = StringBuffer();
    buffer.writeln("--------------------------------");
    buffer.writeln("СЛУЖБОВА ВИДАТА");
    buffer.writeln("Касир: $cashier");
    buffer.writeln("--------------------------------");
    buffer.writeln("Сума: ${amount.toStringAsFixed(2)} UAH");
    buffer.writeln("--------------------------------");
    buffer.writeln("ФН документа: $fiscalNum");
    buffer.writeln("Дата: ${DateTime.now().toString().substring(0, 19)}");
    buffer.writeln("--------------------------------");
    return buffer.toString();
  }

  /// Формує текстовий вигляд Z-звіту
  String _buildZReportVisualization(String fiscalNum) {
    final buffer = StringBuffer();
    buffer.writeln("--------------------------------");
    buffer.writeln("Z-ЗВІТ (Денний звіт)");
    buffer.writeln("--------------------------------");
    buffer.writeln("ПРОДАЖІВ: 15000.00 UAH");
    buffer.writeln("ПОВЕРНЕНЬ: 0.00 UAH");
    buffer.writeln("В КАСІ: 0.00 UAH");
    buffer.writeln("--------------------------------");
    buffer.writeln("ЗМІНА ЗАКРИТА");
    buffer.writeln("ФН звіту: $fiscalNum");
    buffer.writeln("Дата: ${DateTime.now().toString().substring(0, 19)}");
    buffer.writeln("--------------------------------");
    return buffer.toString();
  }

  @override
  Future<CashalotResponse> printXReport({required int prroFiscalNum}) async {
    return CashalotResponse(errorCode: 'SUCCESS');
  }

  @override
  Future<PrroInfo> getPrroInfo({required int prroFiscalNum}) async {
    debugPrint('📡 [CASHALOT] Запит: getPrroInfo()');
    debugPrint('   Параметри:');
    debugPrint('     prroFiscalNum: $prroFiscalNum');
    await _fakeNetworkDelay();
    return PrroInfo(
      numFiscal: prroFiscalNum.toString(),
      name: 'Каса $prroFiscalNum (Mock)',
    );
  }
}
