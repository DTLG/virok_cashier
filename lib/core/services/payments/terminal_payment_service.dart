import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:cash_register/core/config/vchasno_config.dart';

/// Сервіс для роботи з оплатою через термінал з очікуванням підтвердження
///
/// Реалізує схему роботи з терміналами:
/// 1. Запит на оплату з очікуванням підтвердження (task: 6)
/// 2. Завершення операції оплати (task: 7)
///
/// Підтримує протоколи:
/// - POSAPI (для терміналів castles)
/// - PrivatBankJSON (для терміналів Приватбанку)
/// - BPOS1 (для терміналів Ingenico)
class TerminalPaymentService {
  /// Тип протоколу терміналу
  /// Визначає значення поля "device" в запиті
  final TerminalProtocol protocol;

  TerminalPaymentService({this.protocol = TerminalProtocol.posApi});

  /// Отримує значення "device" для запиту залежно від протоколу
  String get _deviceName {
    switch (protocol) {
      case TerminalProtocol.posApi:
        return VchasnoConfig.terminalName;
      case TerminalProtocol.privatJson:
        return "priv";
      case TerminalProtocol.raifJson:
        return "raif";
      case TerminalProtocol.bpos1:
        return "ingenico";
    }
  }

  /// Запит на оплату з очікуванням підтвердження (task: 6)
  ///
  /// Після виклику цього методу:
  /// 1. Покупець прикладає картку до терміналу
  /// 2. Термінал зчитує картку і передає інформацію (PAN, платіжна система)
  /// 3. Облікова система аналізує дані картки
  /// 4. Викликається [finishCardPayment] для завершення або скасування операції
  ///
  /// [amount] - сума до оплати (2 знаки після коми)
  /// [merch] - номер мерчанта (опціонально, для POSAPI)
  ///
  /// Повертає [TerminalPreAuthResult] з інформацією про картку або помилку
  Future<TerminalPreAuthResult> requestCardPreAuth({
    required double amount,
    String? merch,
  }) async {
    try {
      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": _deviceName,
        "type": 3, // Тип завдання для терміналу
        "pay": {
          "task": 6, // Запит на оплату з очікуванням підтвердження
          if (merch != null) "merch": merch,
          "sum": _round(amount),
        },
      };

      debugPrint("💳 [TERMINAL] Запит на оплату з підтвердженням (task: 6)");
      debugPrint("   Сума: ${amount} UAH");
      debugPrint("   Протокол: ${protocol.name}");
      debugPrint("   Device: $_deviceName");
      debugPrint("📤 [TERMINAL] Request: ${jsonEncode(body)}");

      final response = await http
          .post(
            Uri.parse(VchasnoConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 120), // До 2 хвилин очікування карти
            onTimeout: () {
              throw TimeoutException(
                'Таймаут очікування карти на терміналі',
                const Duration(seconds: 120),
              );
            },
          );

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📥 [TERMINAL] Response: ${jsonEncode(jsonResp)}");

      final res = jsonResp['res'] as int? ?? -1;
      final taskStatus = jsonResp['task_status'] as int? ?? -1;
      final errortxt = jsonResp['errortxt'] as String? ?? '';

      if (res == 0 && taskStatus == 1) {
        // Успіх - отримано дані про картку
        final info = jsonResp['info'] as Map<String, dynamic>?;
        if (info != null) {
          final cardMask = info['cardmask'] as String? ?? '';
          final paySys = info['paysys'] as String? ?? '';
          final bankName = info['bankname'] as String? ?? '';

          debugPrint("✅ [TERMINAL] Картка зчитана:");
          debugPrint("   Маска: $cardMask");
          debugPrint("   Платіжна система: $paySys");
          debugPrint("   Банк: $bankName");

          return TerminalPreAuthResult.success(
            cardInfo: TerminalCardInfo(
              cardMask: cardMask,
              paymentSystem: paySys,
              bankName: bankName,
            ),
          );
        }
      }

      // Обробка помилок
      final errorCode = res;
      String errorMessage = errortxt;

      // Спеціальні помилки з документації
      if (errorCode == 5073) {
        errorMessage =
            "Запит на оплату з підтвердженням вже було відправлено на термінал. "
            "Для завершення/скасування операції необхідно відправити task: 7 "
            "або почекати до 70 секунд";
      } else if (errorCode == 1105) {
        errorMessage =
            "Пристрій зайнятий. Почекайте завершення попередньої операції";
      } else if (errorCode == 5074) {
        errorMessage =
            "По терміналу немає активного запиту на оплату з підтвердженням";
      }

      debugPrint(
        "❌ [TERMINAL] Помилка запиту: $errorMessage (Code: $errorCode)",
      );

      return TerminalPreAuthResult.failure(
        message: errorMessage,
        errorCode: errorCode,
      );
    } on TimeoutException catch (e) {
      debugPrint("❌ [TERMINAL] Таймаут очікування карти: $e");
      return TerminalPreAuthResult.failure(
        message:
            'Таймаут очікування карти на терміналі. '
            'Переконайтеся, що термінал активний і покупець приклав картку.',
      );
    } on SocketException catch (e) {
      debugPrint("❌ [TERMINAL] Помилка з'єднання: $e");
      return TerminalPreAuthResult.failure(
        message:
            'Немає зв\'язку з Device Manager. '
            'Перевірте, чи запущено "Вчасно.Каса" і чи є інтернет.',
      );
    } catch (e) {
      debugPrint("❌ [TERMINAL] Невідома помилка: $e");
      return TerminalPreAuthResult.failure(
        message: 'Помилка запиту до терміналу: ${e.toString()}',
      );
    }
  }

  /// Завершення операції оплати (task: 7)
  ///
  /// Викликається після [requestCardPreAuth] для завершення або скасування операції
  ///
  /// [approve] - true для завершення оплати, false для скасування
  /// [overrideAmount] - нова сума для стягнення (тільки для PrivatBankJSON, опціонально)
  ///                    Якщо не вказано, використовується сума з першого запиту
  ///
  /// Повертає [TerminalPaymentResult] з результатом оплати або помилкою
  Future<TerminalPaymentResult> finishCardPayment({
    required bool approve,
    double? overrideAmount,
  }) async {
    try {
      final payBody = <String, dynamic>{
        "task": 7, // Завершення операції оплати
        "oper_action": approve ? 1 : 0, // 1 - продовжити, 0 - скасувати
      };

      // Для PrivatBankJSON можна змінити суму
      if (approve && overrideAmount != null && overrideAmount > 0) {
        payBody["sum"] = _round(overrideAmount);
        debugPrint("💳 [TERMINAL] Зміна суми до: ${overrideAmount} UAH");
      }

      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": _deviceName,
        "type": 3,
        "pay": payBody,
      };

      debugPrint("💳 [TERMINAL] Завершення операції оплати (task: 7)");
      debugPrint("   Дія: ${approve ? "Продовжити оплату" : "Скасувати"}");
      if (overrideAmount != null) {
        debugPrint("   Сума: ${overrideAmount} UAH");
      }
      debugPrint("📤 [TERMINAL] Request: ${jsonEncode(body)}");

      final response = await http
          .post(
            Uri.parse(VchasnoConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException(
                'Таймаут завершення операції на терміналі',
                const Duration(seconds: 60),
              );
            },
          );

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📥 [TERMINAL] Response: ${jsonEncode(jsonResp)}");

      final res = jsonResp['res'] as int? ?? -1;
      final taskStatus = jsonResp['task_status'] as int? ?? -1;
      final errortxt = jsonResp['errortxt'] as String? ?? '';

      if (res == 0 && taskStatus == 1) {
        // Успіх - операція завершена
        final info = jsonResp['info'] as Map<String, dynamic>?;
        if (info != null) {
          debugPrint("✅ [TERMINAL] Оплата успішно завершена");

          return TerminalPaymentResult.success(info: info);
        }
      }

      // Обробка помилок
      final errorCode = res;
      String errorMessage = errortxt;

      if (errorCode == 5074) {
        errorMessage =
            "По терміналу немає активного запиту на оплату з підтвердженням. "
            "Спочатку необхідно відправити task: 6";
      }

      debugPrint(
        "❌ [TERMINAL] Помилка завершення: $errorMessage (Code: $errorCode)",
      );

      return TerminalPaymentResult.failure(
        message: errorMessage,
        errorCode: errorCode,
      );
    } on TimeoutException catch (e) {
      debugPrint("❌ [TERMINAL] Таймаут завершення операції: $e");
      return TerminalPaymentResult.failure(
        message: 'Таймаут завершення операції на терміналі',
      );
    } on SocketException catch (e) {
      debugPrint("❌ [TERMINAL] Помилка з'єднання: $e");
      return TerminalPaymentResult.failure(
        message:
            'Немає зв\'язку з Device Manager. '
            'Перевірте, чи запущено "Вчасно.Каса" і чи є інтернет.',
      );
    } catch (e) {
      debugPrint("❌ [TERMINAL] Невідома помилка: $e");
      return TerminalPaymentResult.failure(
        message: 'Помилка завершення операції: ${e.toString()}',
      );
    }
  }

  /// Округлює до 2 знаків після коми
  double _round(double val) {
    return double.parse(val.toStringAsFixed(2));
  }
}

/// Протокол терміналу
enum TerminalProtocol {
  /// POSAPI (для терміналів castles)
  posApi,

  /// PrivatBankJSON (для терміналів Приватбанку)
  privatJson,

  /// Raiffeisen JSON (для терміналів Райффайзенбанку)
  raifJson,

  /// BPOS1 (для терміналів Ingenico)
  bpos1,
}

/// Інформація про картку, отримана з терміналу
class TerminalCardInfo {
  final String cardMask; // Маска карти (наприклад, "438752******7008")
  final String
  paymentSystem; // Платіжна система (наприклад, "VISA_MER", "Простір")
  final String
  bankName; // Назва банку (наприклад, "ПриватБанк", "Райффайзенбанк")

  TerminalCardInfo({
    required this.cardMask,
    required this.paymentSystem,
    required this.bankName,
  });

  @override
  String toString() {
    return 'TerminalCardInfo(cardMask: $cardMask, paymentSystem: $paymentSystem, bankName: $bankName)';
  }
}

/// Результат запиту на оплату з очікуванням підтвердження (task: 6)
class TerminalPreAuthResult {
  final bool success;
  final String? message;
  final TerminalCardInfo? cardInfo;
  final int? errorCode;

  TerminalPreAuthResult({
    required this.success,
    this.message,
    this.cardInfo,
    this.errorCode,
  });

  factory TerminalPreAuthResult.success({required TerminalCardInfo cardInfo}) {
    return TerminalPreAuthResult(success: true, cardInfo: cardInfo);
  }

  factory TerminalPreAuthResult.failure({
    required String message,
    int? errorCode,
  }) {
    return TerminalPreAuthResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Результат завершення операції оплати (task: 7)
class TerminalPaymentResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? info; // Повна інформація з терміналу
  final int? errorCode;

  TerminalPaymentResult({
    required this.success,
    this.message,
    this.info,
    this.errorCode,
  });

  factory TerminalPaymentResult.success({required Map<String, dynamic> info}) {
    return TerminalPaymentResult(success: true, info: info);
  }

  factory TerminalPaymentResult.failure({
    required String message,
    int? errorCode,
  }) {
    return TerminalPaymentResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }

  /// Отримує маску карти з результату
  String? get cardMask => info?['cardmask'] as String?;

  /// Отримує платіжну систему з результату
  String? get paymentSystem => info?['paysys'] as String?;

  /// Отримує суму оплати з результату
  double? get amount {
    final sum = info?['sum'];
    if (sum is num) return sum.toDouble();
    return null;
  }

  /// Отримує код авторизації з результату
  String? get authCode => info?['payid'] as String?;

  /// Отримує RRN (Reference Number) з результату
  String? get rrn => info?['refundid'] as String?;

  /// Отримує номер чека з результату
  String? get receiptNumber => info?['cancelid'] as String?;

  /// Отримує текст чека з терміналу (старий геттер для сумісності)
  String? get receiptText => info?['sliptxt'] as String?;

  /// Отримує текст банківського сліпа (термінального чека)
  /// Шукає в полях receipt (ПриватБанк) та sliptxt (інші протоколи)
  String? get bankReceiptText {
    if (info == null) return null;
    // ПриватБанк кладе сюди
    if (info!['receipt'] != null && info!['receipt'].toString().isNotEmpty) {
      return info!['receipt'] as String?;
    }
    // Інші протоколи можуть класти сюди
    if (info!['sliptxt'] != null && info!['sliptxt'].toString().isNotEmpty) {
      return info!['sliptxt'] as String?;
    }
    return null;
  }
}
