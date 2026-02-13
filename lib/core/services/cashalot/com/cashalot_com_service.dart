import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cash_register/core/models/cashalot_models.dart';
import 'package:cash_register/core/models/prro_info.dart';
import 'package:cash_register/core/models/pos_result.dart';
import 'package:cash_register/core/services/cashalot/core/cashalot_service.dart';
import 'package:cash_register/core/models/pos_terminal.dart';

class CashalotComService implements CashalotService {
  static const MethodChannel _channel = MethodChannel('com.cashalot/api');

  /// Повна ініціалізація Cashalot COM-addin.
  /// Додано аргументи для ключів та паролів, бо без них COM не працює в тихому режимі.
  Future<void> initialize({
    required String cashalotPath,
    required String fiscalNumber,
    required String keyPath, // Шлях до ПАПКИ з ключем
    required String password, // Пароль до ключа
  }) async {
    try {
      await _setParameter('PathToCashalotDir', cashalotPath);
      await _setParameter('DeviceIDFnRRO', fiscalNumber);

      // !!! НАЙВАЖЛИВІШИЙ ПАРАМЕТР !!!
      // Він забороняє відкриття вікон. Без нього програма зависне.
      await _setParameter('NOINTERFACEMODE', 'True');

      await _setParameter('PathToCertificate', keyPath);
      await _setParameter('PwdToCertificate', password);
      await _setParameter('USETOKEN', 'False');
    } catch (e) {
      debugPrint('❌ [CASHALOT_COM] Init error: $e');
      rethrow;
    }
  }

  /// Допоміжний метод для скорочення коду
  Future<void> _setParameter(String name, String value) async {
    await _channel.invokeMethod('setParameter', {'name': name, 'value': value});
  }

  // ---------------------------------------------------------------------------
  // Реалізація методів
  // ---------------------------------------------------------------------------

  @override
  Future<CashalotResponse> getPrroState({required int prroFiscalNum}) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getCurrentStatus',
        <String, dynamic>{'fiscalNum': prroFiscalNum.toString()},
      );
      return _parseResult(result, 'getPrroState');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  // Додайте в інтерфейс та реалізацію:
  Future<List<PosTerminal>> getPosTerminals(String fiscalNum) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getPOSTerminalList',
        <String, dynamic>{'fiscalNum': fiscalNum},
      );

      // Тут JsonVal може бути масивом, тому парсимо його напряму,
      // не використовуючи _parseResult (який очікує Map).
      final rawJson = result?['jsonVal'] as String?;
      if (rawJson == null || rawJson.isEmpty) return [];

      final decoded = jsonDecode(rawJson);

      if (decoded is List) {
        return decoded.map((e) => PosTerminal.fromJson(e)).toList();
      } else if (decoded is Map<String, dynamic>) {
        // Якщо Cashalot повернув один термінал як об'єкт
        return [PosTerminal.fromJson(decoded)];
      }

      return [];
    } catch (e) {
      debugPrint("❌ [GET_TERMINALS] Error: $e");
      return [];
    }
  }
  // Додайте в CashalotComService:

  Future<CashalotResponse> payByCard({
    required String fiscalNum,
    required double amount,
  }) async {
    try {
      // Форматуємо суму: 10.5 -> "10,50"
      final String amountStr = amount.toStringAsFixed(2).replaceAll('.', ',');

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'payByPaymentCard',
        <String, dynamic>{'fiscalNum': fiscalNum, 'amount': amountStr},
      );

      return _parseResult(result, 'payByPaymentCard');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<CashalotResponse> openShift({required int prroFiscalNum}) async {
    try {
      // ВИПРАВЛЕННЯ: Згідно з документацією Cashalot, OpenShift приймає
      // ТІЛЬКИ фіскальний номер (String), а не JSON з касиром.
      // Авторизація касира відбувається автоматично через ключ/пароль.

      final String payload = prroFiscalNum.toString();

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'openShift',
        <String, dynamic>{'fiscalNum': payload},
      );

      return _parseResult(result, 'openShift');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  // 1. Повернення коштів на терміналі (потрібен RRN оригінальної операції)
  Future<CashalotResponse> returnPaymentByCard({
    required String fiscalNum,
    required double amount,
    required String rrn,
  }) async {
    try {
      final String amountStr = amount.toStringAsFixed(2).replaceAll('.', ',');

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'returnPaymentByCard',
        <String, dynamic>{
          'fiscalNum': fiscalNum,
          'amount': amountStr,
          'rrn': rrn,
        },
      );
      return _parseResult(result, 'returnPaymentByCard');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  // 2. Скасування транзакції (потрібен Invoice Number / номер чека термінала)
  // Використовується, якщо помилково ввели суму, до закриття дня на терміналі
  Future<CashalotResponse> cancelPaymentByCard({
    required String fiscalNum,
    required double amount,
    required String invoiceNum,
  }) async {
    try {
      final String amountStr = amount.toStringAsFixed(2).replaceAll('.', ',');

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'cancelPaymentByCard',
        <String, dynamic>{
          'fiscalNum': fiscalNum,
          'amount': amountStr,
          'invoiceNum': invoiceNum,
        },
      );
      return _parseResult(result, 'cancelPaymentByCard');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  // 3. Фіскалізація чека повернення
  @override
  Future<CashalotResponse> registerReturn({
    required int prroFiscalNum,
    required CheckPayload check,
    required String returnReceiptFiscalNum, // Фіскальний номер чека ПРОДАЖУ
    PosTransactionResult? cardData, // Дані про повернення коштів на картку
  }) async {
    try {
      debugPrint("🔄 [REGISTER_RETURN] Формування чека повернення...");

      // 1. Товари (ReceiptLst) - ідентично до продажу
      final List<Map<String, dynamic>> receiptList = check.checkBody.map((
        item,
      ) {
        final double cost = item.amount * item.price;
        return {
          "VendorCode": item.code,
          "Name": item.name,
          "Quantity": _formatQuantity(item.amount),
          "Price": _formatMoney(item.price),
          "Amount": _formatMoney(cost),
          "UnitType": "шт",
          "IsPriceIncludeVAT": true,
          "GoodsType": 0,
          // Можна додати коментар "Повернення"
        };
      }).toList();

      final jsonGoodsMap = {
        "ReceiptLst": receiptList,
        "Comment": "Повернення товару",
      };

      // 2. Оплата (JSONPayData) - ідентично до продажу
      double sumCash = 0.0;
      double sumCard = 0.0;
      double totalSum = 0.0;

      for (var p in check.checkPay) {
        totalSum += p.sum;
        if (p.payFormNm.toUpperCase().contains("ГОТІВКА")) {
          sumCash += p.sum;
        } else {
          sumCard += p.sum;
        }
      }

      final Map<String, dynamic> jsonPayMap = {
        "SumPayCheck": _formatMoney(totalSum),
        "PaymentOrderType": 0,
      };

      if (sumCash > 0) jsonPayMap["SumCash"] = _formatMoney(sumCash);
      if (sumCard > 0) jsonPayMap["SumPayByCard"] = _formatMoney(sumCard);

      // Додаємо дані повернення з термінала (якщо було)
      if (cardData != null && sumCard > 0) {
        jsonPayMap["RRN"] = cardData.rrn;
        if (cardData.authCode != null)
          jsonPayMap["ApprovalCode"] = cardData.authCode;
        if (cardData.terminalId != null)
          jsonPayMap["TerminalID"] = cardData.terminalId;
        if (cardData.acquireName != null)
          jsonPayMap["AcquireName"] = cardData.acquireName;
        // Номер чека повернення з термінала
        // jsonPayMap["InvoiceNumber"] = ...
      }

      // Видаляємо null
      jsonPayMap.removeWhere((key, value) => value == null);

      final jsonGoods = jsonEncode(jsonGoodsMap);
      final jsonPay = jsonEncode(jsonPayMap);

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'fiscalizeReturnCheck',
        <String, dynamic>{
          'fiscalNum': prroFiscalNum.toString(),
          'jsonGoods': jsonGoods,
          'jsonPay': jsonPay,
          'returnReceiptFiscalNum': returnReceiptFiscalNum,
        },
      );

      return _parseResult(result, 'fiscalizeReturnCheck');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  // Допоміжні методи форматування
  String _formatMoney(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatQuantity(double value) {
    return value.toStringAsFixed(3).replaceAll('.', ',');
  }

  @override
  Future<CashalotResponse> registerSale({
    required int prroFiscalNum,
    required CheckPayload check,
    PosTransactionResult? cardData,
  }) async {
    try {
      debugPrint("🛒 [REGISTER_SALE] Формування чека згідно документації...");

      // ==========================================
      // 1. ФОРМУВАННЯ СПИСКУ ТОВАРІВ (ReceiptLst)
      // ==========================================
      final List<Map<String, dynamic>> receiptList = check.checkBody.map((
        item,
      ) {
        final double cost = item.amount * item.price;

        return {
          // Обов'язкові поля згідно документації:
          "VendorCode": item.code, // Артикул
          "Name": item.name, // Назва
          "Quantity": _formatQuantity(item.amount), // Кількість
          "Price": _formatMoney(item.price), // Ціна
          "Amount": _formatMoney(cost), // Вартість (К-сть * Ціна)
          "UnitType": "шт", // Одиниця виміру (ОБОВ'ЯЗКОВО!)
          // Податкові налаштування (Приклад для ПДВ 20%)
          // Якщо ви ФОП без ПДВ, логіка може відрізнятися (наприклад, VATRate: "0" або "Без ПДВ")
          "IsPriceIncludeVAT": true, // Чи включено ПДВ в ціну
          //"VATRate": "20",                 // Ставка ПДВ (якщо потрібно)
          //"VATLetter": "A",                // Літера ставки (А, Б, В...)

          // Додаткові поля (за потреби)
          "GoodsType": 0, // 0 - товар, 1 - послуга
        };
      }).toList();

      // Огортаємо в кореневий об'єкт ReceiptLst
      final jsonGoodsMap = {
        "ReceiptLst": receiptList,
        // Можна додати коментар до чека
        "Comment": "Чек з Flutter App",
      };

      // ==========================================
      // 2. ФОРМУВАННЯ ОПЛАТИ (JSONPayData)
      // ==========================================
      // Cashalot вимагає не список оплат, а підсумки по типах!

      double sumCash = 0.0;
      double sumCard = 0.0;
      double totalSum = 0.0;

      for (var p in check.checkPay) {
        totalSum += p.sum;
        if (p.payFormNm.toUpperCase().contains("ГОТІВКА")) {
          sumCash += p.sum;
        } else {
          sumCard += p.sum;
        }
      }

      // Базовий JSON оплат
      final Map<String, dynamic> jsonPayMap = {
        "SumPayCheck": _formatMoney(totalSum),
        "SumCash": sumCash > 0 ? _formatMoney(sumCash) : null,
        "SumPayByCard": sumCard > 0 ? _formatMoney(sumCard) : null,
        "SumPayByCredit": null,
        "SumPayByCertificate": null,
        "PaymentOrderType": 0,
      };

      // Додаємо дані з термінала, якщо є оплата карткою
      if (cardData != null && sumCard > 0) {
        jsonPayMap["RRN"] = cardData.rrn;
        jsonPayMap["ApprovalCode"] = cardData.authCode;
        jsonPayMap["TerminalID"] = cardData.terminalId;
        jsonPayMap["IssuerName"] = cardData.paymentSystem;
        jsonPayMap["PAN"] = cardData.cardPan;
        jsonPayMap["AcquireName"] = cardData.acquireName;
        if (cardData.transactionDate != null) {
          jsonPayMap["TransactionDate"] = cardData.transactionDate;
        }
      }

      // 3. Кодуємо в JSON String
      final jsonGoods = jsonEncode(jsonGoodsMap);

      // Для оплати прибираємо null значення, щоб не засмічувати JSON
      jsonPayMap.removeWhere((key, value) => value == null);
      final jsonPay = jsonEncode(jsonPayMap);

      debugPrint("📦 Goods JSON (ReceiptLst): $jsonGoods");
      debugPrint("💳 Pay JSON: $jsonPay");

      // 4. Відправляємо в C++
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'fiscalizeCheck',
        <String, dynamic>{
          'fiscalNum': prroFiscalNum.toString(),
          'jsonGoods': jsonGoods,
          'jsonPay': jsonPay,
        },
      );

      return _parseResult(result, 'registerSale');
    } catch (e) {
      debugPrint("❌ [REGISTER_SALE] Exception: $e");
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<CashalotResponse> closeShift({required int prroFiscalNum}) async {
    try {
      debugPrint('🔒 [CASHALOT_COM] closeShift: fiscalNum=$prroFiscalNum');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'closeShift',
        <String, dynamic>{'fiscalNum': prroFiscalNum.toString()},
      );
      debugPrint('🔒 [CASHALOT_COM] closeShift result: $result');
      return _parseResult(result, 'closeShift');
    } catch (e) {
      debugPrint('❌ [CASHALOT_COM] closeShift error: $e');
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<CashalotResponse> printXReport({required int prroFiscalNum}) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'printXReport',
        <String, dynamic>{'fiscalNum': prroFiscalNum.toString()},
      );
      return _parseResult(result, 'printXReport');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<CashalotResponse> serviceDeposit({
    required int prroFiscalNum,
    required double amount,
    required String cashier,
  }) async {
    try {
      // Викликаємо новий C++ метод serviceInput
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'serviceInput',
        <String, dynamic>{
          'fiscalNum': prroFiscalNum.toString(),
          'amount': amount, // Передаємо double
        },
      );
      return _parseResult(result, 'serviceDeposit');
    } catch (e) {
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<CashalotResponse> serviceIssue({
    required int prroFiscalNum,
    required double amount,
    required String cashier,
  }) async {
    try {
      debugPrint(
        '💸 [CASHALOT_COM] serviceIssue: fiscalNum=$prroFiscalNum, amount=$amount',
      );
      // Викликаємо новий C++ метод serviceOutput
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'serviceOutput',
        <String, dynamic>{
          'fiscalNum': prroFiscalNum.toString(),
          'amount': amount,
        },
      );
      debugPrint('💸 [CASHALOT_COM] serviceIssue result: $result');
      return _parseResult(result, 'serviceIssue');
    } catch (e) {
      debugPrint('❌ [CASHALOT_COM] serviceIssue error: $e');
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<List<PrroInfo>> getAvailablePrros() async => [];

  @override
  Future<List<PrroInfo>> getAvailablePrrosInfo() async => [];

  @override
  Future<PrroInfo> getPrroInfo({required int prroFiscalNum}) async {
    throw UnimplementedError();
  }

  @override
  Future<CashalotResponse> cleanupCashalot({required int prroFiscalNum}) async {
    return CashalotResponse(errorCode: null);
  }

  // ---------------------------------------------------------------------------
  // ПАРСИНГ (Уніфікований)
  // ---------------------------------------------------------------------------
  CashalotResponse _parseResult(Map<dynamic, dynamic>? result, String method) {
    // 1. Перевірка на null (технічна помилка каналу)
    if (result == null) {
      return CashalotResponse(
        errorCode: 'NO_DATA',
        errorMessage: 'Null result from $method',
      );
    }

    final bool isComSuccess = result['success'] == true;
    final String? rawJson = result['jsonVal'] as String?;

    // 2. Декодуємо JSON
    Map<String, dynamic>? parsedJson;
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map<String, dynamic>) {
          parsedJson = decoded;
        } else if (decoded is List) {
          // Якщо прийшов список (наприклад, масив параметрів),
          // обгортаємо його в поле Values для уніфікації.
          parsedJson = <String, dynamic>{'Values': decoded};
        }
      } catch (e) {
        debugPrint('⚠️ JSON Decode Error: $e');
      }
    }

    // 3. Обробка помилок рівня COM (коли DLL повернула false)
    if (!isComSuccess) {
      String errorText = 'COM method returned false';
      if (parsedJson != null) {
        errorText =
            parsedJson['ErrorString'] ??
            parsedJson['ErrorMessage'] ??
            parsedJson['Description'] ??
            errorText;
      }
      return CashalotResponse(errorCode: 'API_ERROR', errorMessage: errorText);
    }

    if (parsedJson == null) {
      return CashalotResponse(
        errorCode: 'JSON_ERROR',
        errorMessage: 'Empty JSON',
      );
    }

    // 4. Обробка логічних помилок Cashalot (коли Ret = false)
    // Іноді COM повертає true, але всередині JSON каже, що операція не вдалася
    if (parsedJson['Ret'] == false) {
      return CashalotResponse(
        errorCode: 'LOGIC_ERROR',
        errorMessage: parsedJson['ErrorString'] ?? 'Unknown logic error',
      );
    }

    // 5. Успіх! Парсимо корисні дані (Values)
    return _parseResponseData(parsedJson);
  }

  // Допоміжний метод для витягування даних
  CashalotResponse _parseResponseData(Map<String, dynamic> json) {
    final values = json['Values'];

    // Якщо Values це Map (як у випадку з X-звітом)
    if (values is Map<String, dynamic>) {
      // Специфічна логіка для звітів (X або Z)
      if (values.containsKey('Base64Str1251ReportXML')) {
        return CashalotResponse(
          errorCode: null,
          errorMessage: null,
          visualization: values['Base64Str1251ReportXML'],

          // Тут ми повертаємо весь об'єкт Values або конкретне поле
          // Припустимо, у вашому CashalotResponse є поле data типу Map<String, dynamic>?
          data: values,
        );
      }

      // Для відкриття зміни там може бути ShiftID
      if (values.containsKey('ShiftID')) {
        return CashalotResponse(errorCode: null, data: values);
      }
    }

    // Дефолтний успішний респонс, якщо немає специфічних даних
    return CashalotResponse(
      errorCode: null,
      data: values is Map<String, dynamic> ? values : {},
    );
  }
}
