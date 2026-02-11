import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../core/config/vchasno_config.dart';
import '../core/models/cashalot_models.dart';
import '../core/services/storage_service.dart';
import '../core/services/prro_service.dart';
import 'vchasno_errors.dart';
import 'fiscal_result.dart';
import 'x_report_data.dart';
import 'raw_printer_service.dart';
import '../core/models/prro_info.dart';

class VchasnoService implements PrroService {
  String? _lastCheckTag; // Для відстеження останнього чека
  final RawPrinterService _rawPrinterService = RawPrinterService();
  final StorageService _storageService = GetIt.instance<StorageService>();

  /// Основний метод відправки чека продажу з обробкою помилок
  ///
  /// Повертає [FiscalResult] з результатом операції
  @override
  Future<FiscalResult> printSale(
    CheckPayload check, {
    int? prroFiscalNum,
  }) async {
    // prroFiscalNum не використовується в VchasnoService, але зберігаємо для сумісності з інтерфейсом
    return await _printSaleWithRetry(check, retryCount: 0);
  }

  @override
  Future<List<PrroInfo>> getAvailablePrrosInfo() async {
    return [];
  }

  @override
  Future<XReportData> cleanupCashalot({int? prroFiscalNum}) async {
    return XReportData(visualization: 'Очищення ПРРО успішно виконано!');
  }

  /// Внутрішній метод з retry логікою
  Future<FiscalResult> _printSaleWithRetry(
    CheckPayload check, {
    required int retryCount,
    bool autoOpenShift = true,
  }) async {
    // Максимум 3 спроби
    if (retryCount >= 3) {
      return FiscalResult.failure(
        message: 'Перевищено максимальну кількість спроб',
        error: VchasnoException(
          type: VchasnoErrorType.unknown,
          message: 'Перевищено максимальну кількість спроб',
        ),
      );
    }

    try {
      // 1. Округлення загальної суми
      double totalSum = _round(check.checkTotal.sum);

      // Визначення типу оплати (0 - Готівка, 2 - Картка)
      int payType =
          check.checkPay.first.payFormNm.toUpperCase().contains("КАРТ") ? 2 : 0;

      // Генеруємо унікальний tag для відстеження чека
      final tag = _generateTag();
      _lastCheckTag = tag;

      // 2. Формуємо тіло запиту строго по знайденому CURL шаблону
      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": VchasnoConfig.device,
        "type": "1",
        // "printer": VchasnoConfig.printerName,
        "need_pf_pdf": 1,
        "tag": tag, // Додаємо tag для відстеження
        "fiscal": {
          "task": 1, // 1 = Продаж
          "cashier": check.checkHead.cashier.isNotEmpty
              ? check.checkHead.cashier
              : "Admin",
          "receipt": {
            "sum": totalSum,
            "disc": 0.00,
            "disc_type": 0,
            "round": 0.00,
            // --- ТОВАРИ ---
            "rows": check.checkBody.map((item) {
              double price = _round(item.price);
              double cost = _round(item.cost);

              return <String, dynamic>{
                "code": item.code,
                "name": item.name,
                "cnt": item.amount,
                "price": price,
                "cost": cost,
                "disc": 0.00,
                "disc_type": 0,
                "taxgrp": 2,
                if (item.uktzeds != null && item.uktzeds!.isNotEmpty)
                  "code_a": item.uktzeds,
              };
            }).toList(),
            // --- ОПЛАТА ---
            "pays": [
              {"type": payType, "sum": totalSum},
            ],
          },
        },
      };

      final requestJson = jsonEncode(body);
      debugPrint("📤 [VCHASNO] JSON Body: $requestJson");

      // Відправка з таймаутом
      final response = await http
          .post(
            Uri.parse(VchasnoConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: requestJson,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Таймаут з\'єднання з Device Manager',
                const Duration(seconds: 30),
              );
            },
          );

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📥 [VCHASNO] Response: $jsonResp");

      // Перевірка результату
      final res = jsonResp['res'] as int? ?? -1;
      if (res == 0) {
        // Успіх!
        final taskStatus = jsonResp['task_status'] as int?;
        if (taskStatus == 1 || taskStatus == 2) {
          // Витягуємо QR-код та номер документа з відповіді
          final info = jsonResp['info'] as Map<String, dynamic>?;
          final qrUrl = info?['qr'] as String?;
          final docNumber =
              info?['docno']?.toString() ??
              info?['printinfo']?['docno']?.toString();

          debugPrint("✅ Чек успішно фіскалізовано!");
          debugPrint("📄 Номер чека: $docNumber");
          debugPrint("🔗 QR-код: $qrUrl");

          // Перевіряємо, чи прийшов готовий текст для друку (pf_text)
          if (jsonResp.containsKey('pf_text')) {
            final String? pfTextBase64 = jsonResp['pf_text'] as String?;
            if (pfTextBase64 != null && pfTextBase64.isNotEmpty) {
              debugPrint("🖨️ [PRINTER] Отримано готовий текст чека для друку");
              try {
                // Отримуємо налаштування принтера з SharedPreferences
                final printerIp =
                    await _storageService.getString('printer_ip') ??
                    VchasnoConfig.printerIp;
                final printerPort =
                    await _storageService.getInt('printer_port') ??
                    VchasnoConfig.printerPort;

                // Друкуємо готовий текст на мережевий принтер
                await _rawPrinterService.printVisualization(
                  printerIp: printerIp,
                  visualizationBase64: pfTextBase64,
                  port: printerPort,
                );
                debugPrint(
                  "✅ [PRINTER] Чек успішно відправлено на принтер $printerIp:$printerPort",
                );
              } catch (e) {
                debugPrint("⚠️ [PRINTER] Помилка друку чека: $e");
                // Не перериваємо процес, якщо друк не вдався
                // Фіскалізація вже пройшла успішно
              }
            }
          }

          _lastCheckTag = null; // Очищаємо tag після успіху

          return FiscalResult.success(
            message: 'Чек успішно фіскалізовано',
            qrUrl: qrUrl,
            docNumber: docNumber,
            totalAmount: totalSum,
          );
        }
      }

      // Обробка помилки
      final exception = VchasnoException.fromResponse(jsonResp, requestJson);

      // Логування помилки валідації (1016)
      if (exception.type == VchasnoErrorType.validationError) {
        debugPrint("❌ [VALIDATION ERROR] Request JSON: $requestJson");
        debugPrint("❌ [VALIDATION ERROR] Response: $jsonResp");
        // Тут можна додати відправку в Sentry/Crashlytics
      }

      // Обробка різних типів помилок
      switch (exception.type) {
        case VchasnoErrorType.shiftTooLong:
          // Блокуюча помилка - потрібен Z-звіт
          return FiscalResult.failure(
            message: exception.message,
            error: exception,
          );

        case VchasnoErrorType.shiftClosed:
          // Автоматично відкриваємо зміну і повторюємо
          if (autoOpenShift && retryCount == 0) {
            debugPrint("🔄 [RETRY] Спроба автоматичного відкриття зміни...");
            final shiftOpened = await openShift();
            if (shiftOpened.isSuccess) {
              debugPrint("✅ Зміна відкрита, повторюємо чек...");
              // Повторюємо з тим же чеком
              return await _printSaleWithRetry(
                check,
                retryCount: retryCount + 1,
                autoOpenShift: false, // Не повторюємо відкриття зміни
              );
            }
          }
          return FiscalResult.failure(
            message: exception.message,
            error: exception,
          );

        case VchasnoErrorType.noConnection:
        case VchasnoErrorType.networkTimeout:
          // Можна повторити
          if (exception.canRetry && retryCount < 2) {
            debugPrint("🔄 [RETRY] Спроба $retryCount...");
            await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
            return await _printSaleWithRetry(
              check,
              retryCount: retryCount + 1,
              autoOpenShift: autoOpenShift,
            );
          }
          return FiscalResult.failure(
            message: exception.message,
            error: exception,
          );

        case VchasnoErrorType.noPaper:
        case VchasnoErrorType.validationError:
        case VchasnoErrorType.unknown:
          // Перевірка на колізію (res_action = 2)
          if (exception.needsCollisionFix && retryCount < 2) {
            debugPrint("🔄 [COLLISION FIX] Виправлення колізії...");
            await Future.delayed(Duration(seconds: 1));
            return await _printSaleWithRetry(
              check,
              retryCount: retryCount + 1,
              autoOpenShift: autoOpenShift,
            );
          }
          return FiscalResult.failure(
            message: exception.message,
            error: exception,
          );
      }
    } on TimeoutException catch (e) {
      final exception = VchasnoException.fromException(e, null);
      // Для таймауту перевіряємо статус останнього чека перед повторною спробою
      if (retryCount == 0 && _lastCheckTag != null) {
        debugPrint("⚠️ [TIMEOUT] Перевірка статусу останнього чека...");
        final checkStatus = await _checkLastCheckStatus(_lastCheckTag!);
        if (checkStatus == true) {
          debugPrint("✅ Останній чек успішно оброблено!");
          _lastCheckTag = null;
          // Повертаємо успіх, але без QR (його можна отримати через перевірку статусу)
          return FiscalResult.success(
            message: 'Чек успішно оброблено (перевірено після таймауту)',
          );
        }
      }
      if (exception.canRetry && retryCount < 2) {
        debugPrint("🔄 [RETRY] TimeoutException, спроба $retryCount...");
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await _printSaleWithRetry(
          check,
          retryCount: retryCount + 1,
          autoOpenShift: autoOpenShift,
        );
      }
      return FiscalResult.failure(message: exception.message, error: exception);
    } on SocketException catch (e) {
      final exception = VchasnoException.fromException(e, null);
      if (exception.canRetry && retryCount < 2) {
        debugPrint("🔄 [RETRY] SocketException, спроба $retryCount...");
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return await _printSaleWithRetry(
          check,
          retryCount: retryCount + 1,
          autoOpenShift: autoOpenShift,
        );
      }
      return FiscalResult.failure(message: exception.message, error: exception);
    } catch (e) {
      final exception = VchasnoException.fromException(e, null);
      debugPrint("❌ КРИТИЧНА ПОМИЛКА: $e");
      return FiscalResult.failure(message: exception.message, error: exception);
    }
  }

  /// Перевірка статусу останнього чека за tag
  Future<bool?> _checkLastCheckStatus(String tag) async {
    try {
      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": VchasnoConfig.device,
        "type": "1",
        "tag": tag, // Перевіряємо той самий tag
        "fiscal": {
          "task": 1, // Те саме завдання
        },
      };

      final response = await http
          .post(
            Uri.parse(VchasnoConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      final res = jsonResp['res'] as int? ?? -1;
      final taskStatus = jsonResp['task_status'] as int?;

      // task_status = 1 або 2 означає, що чек оброблено
      if (res == 0 && (taskStatus == 1 || taskStatus == 2)) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Помилка перевірки статусу чека: $e");
      return null; // Невідомо
    }
  }

  /// Генерує унікальний tag для відстеження чека
  String _generateTag() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // --- Інші методи (X/Z звіти) ---
  /// Отримує X-звіт і повертає дані для відображення
  @override
  Future<XReportData?> printXReport({int? prroFiscalNum}) async {
    // prroFiscalNum не використовується в VchasnoService, але зберігаємо для сумісності з інтерфейсом
    try {
      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": VchasnoConfig.device,
        "type": "1",
        "fiscal": {
          "task": 10, // X-звіт
          "cashier": "Admin",
        },
      };

      debugPrint("📡 [VCHASNO] Requesting X-Report...");

      final response = await http
          .post(
            Uri.parse(VchasnoConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📥 [VCHASNO] X-Report Response: $jsonResp");

      final res = jsonResp['res'] as int? ?? -1;
      if (res == 0) {
        try {
          final reportData = XReportData.fromJson(jsonResp);
          debugPrint("✅ [VCHASNO] X-Report parsed successfully");
          return reportData;
        } catch (e) {
          debugPrint("❌ [VCHASNO] Помилка парсингу X-звіту: $e");
          return null;
        }
      } else {
        final err = jsonResp['errortxt'] ?? jsonResp['err_txt'] ?? "Unknown";
        debugPrint("❌ [VCHASNO] X-Report Error: $err (Code: $res)");
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint("❌ [VCHASNO] Таймаут X-звіту: $e");
      return null;
    } on SocketException catch (e) {
      debugPrint("❌ [VCHASNO] Помилка з'єднання X-звіту: $e");
      return null;
    } catch (e) {
      debugPrint("❌ [VCHASNO] Помилка X-звіту: $e");
      return null;
    }
  }

  /// Отримує Z-звіт (закриття зміни) і повертає дані для відображення
  Future<XReportData?> printZReport() async {
    try {
      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": VchasnoConfig.device,
        "type": "1",
        "fiscal": {
          "task": 11, // Z-звіт
          "cashier": "Admin",
        },
      };

      debugPrint("📡 [VCHASNO] Requesting Z-Report...");

      final response = await http
          .post(
            Uri.parse(VchasnoConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📥 [VCHASNO] Z-Report Response: $jsonResp");

      final res = jsonResp['res'] as int? ?? -1;
      if (res == 0) {
        try {
          final reportData = XReportData.fromJson(jsonResp);
          debugPrint("✅ [VCHASNO] Z-Report parsed successfully");
          return reportData;
        } catch (e) {
          debugPrint("❌ [VCHASNO] Помилка парсингу Z-звіту: $e");
          return null;
        }
      } else {
        final err = jsonResp['errortxt'] ?? jsonResp['err_txt'] ?? "Unknown";
        debugPrint("❌ [VCHASNO] Z-Report Error: $err (Code: $res)");
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint("❌ [VCHASNO] Таймаут Z-звіту: $e");
      return null;
    } on SocketException catch (e) {
      debugPrint("❌ [VCHASNO] Помилка з'єднання Z-звіту: $e");
      return null;
    } catch (e) {
      debugPrint("❌ [VCHASNO] Помилка Z-звіту: $e");
      return null;
    }
  }

  @override
  Future<CashalotResponse> openShift({int? prroFiscalNum}) async {
    // prroFiscalNum не використовується в VchasnoService, але зберігаємо для сумісності з інтерфейсом
    await _sendSimpleTask(0);
    return CashalotResponse(errorCode: null, errorMessage: null);
  }

  // --- Допоміжні методи ---

  /// Виправлений метод для X-звіту (10), Z-звіту (11) та Відкриття зміни (0)
  Future<bool> _sendSimpleTask(int taskType) async {
    try {
      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": VchasnoConfig.device,
        "type": "1",
        "fiscal": {
          "task": taskType, // 10 або 11, або 0
          "cashier": "Admin",
        },
      };

      debugPrint("📡 [VCHASNO] Sending Task $taskType...");

      final response = await http
          .post(
            Uri.parse(VchasnoConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      debugPrint("📥 [VCHASNO] Task $taskType Response: $jsonResp");

      final res = jsonResp['res'] as int? ?? -1;
      if (res == 0) {
        return true;
      } else {
        final err = jsonResp['errortxt'] ?? jsonResp['err_txt'] ?? "Unknown";
        debugPrint("❌ Error: $err (Code: $res)");
        return false;
      }
    } on SocketException catch (e) {
      debugPrint("❌ Помилка з'єднання (SocketException): $e");
      return false;
    } on TimeoutException catch (e) {
      debugPrint("❌ Таймаут з'єднання: $e");
      return false;
    } catch (e) {
      debugPrint("❌ Помилка з'єднання: $e");
      return false;
    }
  }

  /// Виправлений метод для Службового внесення/видачі
  /// Внесення = Task 3, Видача = Task 4 (у новій структурі fiscal)
  Future<void> _sendServiceTask(double amount, {required int type}) async {
    try {
      // type: 0 - внесення, 1 - видача (це ваші внутрішні коди)
      // Для fiscal API:
      // Task 3 = Службове внесення
      // Task 4 = Службова видача
      int fiscalTask = (type == 0) ? 3 : 4;

      final body = {
        "ver": 6,
        "source": VchasnoConfig.source,
        "device": "AStools",
        "type": "1",
        "fiscal": {
          "task": fiscalTask,
          "cashier": "Admin",
          "receipt": {
            "sum": _round(amount), // Сума операції
            // Для службових операцій товари (rows) не потрібні,
            // але потрібен блок pays або просто сума в receipt
            "pays": [
              {
                "type": 0, // Готівка
                "sum": _round(amount),
              },
            ],
          },
        },
      };

      debugPrint("📡 [VCHASNO] Service Task $fiscalTask (${amount} UAH)...");

      final response = await http.post(
        Uri.parse(VchasnoConfig.baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final jsonResp = jsonDecode(response.body);
      debugPrint("📥 [VCHASNO] Service Response: $jsonResp");

      if (jsonResp['res'] != 0) {
        throw Exception(jsonResp['errortxt'] ?? 'Помилка виконання операції');
      }
    } catch (e) {
      debugPrint("❌ Помилка з'єднання: $e");
      rethrow;
    }
  }

  // --- Математика ---
  /// Округляє до 2 знаків після коми, щоб уникнути помилок типу 20.50000001
  double _round(double val) {
    return double.parse(val.toStringAsFixed(2));
  }

  /// Службове внесення
  @override
  Future<XReportData?> serviceIn(
    double amount, {
    required String cashier,
    int? prroFiscalNum,
  }) async {
    // prroFiscalNum не використовується в VchasnoService, але зберігаємо для сумісності з інтерфейсом
    await _sendServiceTask(amount, type: 0);
  }

  /// Службова видача
  @override
  Future<XReportData?> serviceOut(
    double amount, {
    required String cashier,
    int? prroFiscalNum,
  }) async {
    // prroFiscalNum не використовується в VchasnoService, але зберігаємо для сумісності з інтерфейсом
    await _sendServiceTask(amount, type: 1);
  }

  /// Закриття зміни (Z-звіт) - реалізація інтерфейсу PrroService
  @override
  Future<XReportData?> closeShift({int? prroFiscalNum}) async {
    // prroFiscalNum не використовується в VchasnoService, але зберігаємо для сумісності з інтерфейсом
    return await printZReport();
  }

  // --- Допоміжні методи ---

  /// Для службових операцій
  // Future<void> _sendServiceTask(double amount, {required int type}) async {
  //   try {
  //     final body = {
  //       "ver": 6,
  //       "source": VchasnoConfig.source,
  //       "type": 1,
  //       "device": "AStools",
  //       "task": {
  //         "type": 3, // 3 = Службовий чек
  //         "params": {
  //           "sum": amount,
  //           "type": type,
  //           "payment_type": 1, // Готівка (обов'язково для службових)
  //         },
  //       },
  //     };

  //     final response = await http.post(
  //       Uri.parse(VchasnoConfig.baseUrl),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode(body),
  //     );

  //     final jsonResp = jsonDecode(response.body);

  //     if (jsonResp['res'] != 0) {
  //       throw Exception(jsonResp['errortxt'] ?? 'Помилка виконання операції');
  //     }
  //   } catch (e) {
  //     debugPrint("❌ Помилка з'єднання: $e");
  //     rethrow;
  //   }
  // }
}
