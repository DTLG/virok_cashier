import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import '../models/cashalot_models.dart';
import '../models/prro_info.dart';
import '../models/pos_result.dart';
import 'cashalot_service.dart';
import 'cashalot_api_client.dart';

/// Реальна реалізація CashalotService
/// Використовує CashalotApiClient для роботи з реальним API
/// Використовує ключі (Certificate + PrivateKey + Password) для автентифікації
class RealCashalotService implements CashalotService {
  final CashalotApiClient _apiClient;
  final String? defaultPrroFiscalNum;

  // Шляхи до ключів в assets
  final String _keyPath;
  final String _certPath;
  final String _keyPassword;

  // Кешовані Base64 рядки (щоб не читати файл щоразу)
  String? _cachedKeyBase64;
  String? _cachedCertBase64;

  /// Створює RealCashalotService
  /// [baseUrl] - базовий URL API (наприклад, 'https://fsapi.cashalot.org.ua')
  /// [keyPath] - шлях до ключа в assets (наприклад, 'assets/keys/Key-6.dat')
  /// [certPath] - шлях до сертифіката в assets (наприклад, 'assets/keys/Cert.crt')
  /// [keyPassword] - пароль від ключа
  /// [defaultPrroFiscalNum] - фіскальний номер ПРРО за замовчуванням (опціонально)
  /// [timeout] - таймаут для запитів
  RealCashalotService({
    required String baseUrl,
    required String keyPath,
    required String certPath,
    required String keyPassword,
    this.defaultPrroFiscalNum,
    Duration timeout = const Duration(seconds: 20),
  }) : _apiClient = CashalotApiClient(baseUrl: baseUrl, timeout: timeout),
       _keyPath = keyPath,
       _certPath = certPath,
       _keyPassword = keyPassword;

  /// Створює RealCashalotService з вже налаштованим API клієнтом
  RealCashalotService.withClient({
    required CashalotApiClient apiClient,
    required String keyPath,
    required String certPath,
    required String keyPassword,
    String? defaultPrroFiscalNum,
  }) : _apiClient = apiClient,
       _keyPath = keyPath,
       _certPath = certPath,
       _keyPassword = keyPassword,
       defaultPrroFiscalNum = defaultPrroFiscalNum;

  /// Завантажує ключі та конвертує в Base64
  /// Підтримує читання як з assets, так і з файлової системи
  Future<void> _ensureKeysLoaded() async {
    if (_cachedKeyBase64 != null && _cachedCertBase64 != null) return;

    try {
      debugPrint('🔑 [CASHALOT] Завантаження ключів...');
      debugPrint('   Ключ: $_keyPath');
      debugPrint('   Сертифікат: $_certPath');

      Uint8List keyList;
      Uint8List certList;

      // Перевіряємо, чи це шлях до файлу в файловій системі
      try {
        final keyFile = File(_keyPath);
        final certFile = File(_certPath);

        if (await keyFile.exists() && await certFile.exists()) {
          // Читаємо з файлової системи
          debugPrint('📁 [CASHALOT] Читання ключів з файлової системи...');
          keyList = await keyFile.readAsBytes();
          certList = await certFile.readAsBytes();
        } else {
          // Якщо файли не існують, пробуємо читати з assets
          debugPrint('📦 [CASHALOT] Файли не знайдено, читання з assets...');
          final keyBytes = await rootBundle.load(_keyPath);
          final certBytes = await rootBundle.load(_certPath);
          keyList = keyBytes.buffer.asUint8List();
          certList = certBytes.buffer.asUint8List();
        }
      } catch (e) {
        // Якщо помилка при роботі з файлами, пробуємо assets
        debugPrint('⚠️ [CASHALOT] Помилка роботи з файлами: $e');
        debugPrint('📦 [CASHALOT] Спробуємо читати з assets...');
        final keyBytes = await rootBundle.load(_keyPath);
        final certBytes = await rootBundle.load(_certPath);
        keyList = keyBytes.buffer.asUint8List();
        certList = certBytes.buffer.asUint8List();
      }

      _cachedKeyBase64 = base64Encode(keyList);
      _cachedCertBase64 = base64Encode(certList);

      debugPrint('✅ [CASHALOT] Ключі успішно завантажені');
      debugPrint('   Розмір ключа: ${keyList.length} байт');
      debugPrint('   Розмір сертифіката: ${certList.length} байт');
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка читання ключів: $e');
      rethrow;
    }
  }

  /// Отримує параметри автентифікації (ключі)
  Future<Map<String, dynamic>> _getAuthParams() async {
    await _ensureKeysLoaded();
    return {
      "Certificate": _cachedCertBase64!,
      "PrivateKey": _cachedKeyBase64!,
      "Password": _keyPassword,
    };
  }

  @override
  Future<List<PrroInfo>> getAvailablePrros() async {
    try {
      debugPrint('📡 [CASHALOT] Запит: getAvailablePrros()');
      debugPrint('🔍 Шукаємо доступні ПРРО для вашого ключа...');

      final authParams = await _getAuthParams();

      // Викликаємо команду Objects для отримання реального списку ПРРО
      final response = await _apiClient.getObjects(authParams: authParams);

      debugPrint('📥 [CASHALOT] Відповідь Objects:');
      debugPrint('   ${const JsonEncoder.withIndent('   ').convert(response)}');

      final List<PrroInfo> result = [];

      // Парсимо складну структуру відповіді Cashalot
      // Структура: TaxObjects -> TransactionsRegistrars -> NumFiscal
      if (response['TaxObjects'] != null) {
        final taxObjects = response['TaxObjects'] as List?;
        if (taxObjects != null) {
          for (var taxObj in taxObjects) {
            if (taxObj is Map<String, dynamic>) {
              if (taxObj['TransactionsRegistrars'] != null) {
                final registrars = taxObj['TransactionsRegistrars'] as List?;
                if (registrars != null) {
                  for (var prro in registrars) {
                    if (prro is Map<String, dynamic>) {
                      final numFiscal = prro['NumFiscal'];
                      if (numFiscal != null) {
                        final numFiscalStr = numFiscal.toString();
                        final name = prro['Name'] as String? ?? 'Без назви';
                        result.add(
                          PrroInfo(numFiscal: numFiscalStr, name: name),
                        );
                        debugPrint(
                          '✅ [CASHALOT] ЗНАЙДЕНО ПРРО: $name -> $numFiscalStr',
                        );
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      if (result.isEmpty) {
        debugPrint('⚠️ [CASHALOT] ПРРО не знайдено в відповіді Objects');
        // Fallback: якщо є defaultPrroFiscalNum, повертаємо його
        final defaultPrro = defaultPrroFiscalNum;
        if (defaultPrro != null) {
          debugPrint(
            '📥 [CASHALOT] Використовується default ПРРО: $defaultPrro',
          );
          return [
            PrroInfo(numFiscal: defaultPrro, name: 'Каса за замовчуванням'),
          ];
        }
      } else {
        debugPrint('✅ [CASHALOT] Знайдено ${result.length} ПРРО: $result');
      }

      return result;
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка getAvailablePrros: $e');
      // Fallback: якщо є defaultPrroFiscalNum, повертаємо його
      final defaultPrro = defaultPrroFiscalNum;
      if (defaultPrro != null) {
        debugPrint(
          '⚠️ [CASHALOT] Використовується default ПРРО через помилку: $defaultPrro',
        );
        return [
          PrroInfo(numFiscal: defaultPrro, name: 'Каса за замовчуванням'),
        ];
      }
      rethrow;
    }
  }

  @override
  Future<List<PrroInfo>> getAvailablePrrosInfo() async {
    try {
      // debugPrint('📡 [CASHALOT] Запит: getAvailablePrrosInfo()');
      // debugPrint('🔍 Шукаємо доступні ПРРО для вашого ключа...');

      final authParams = await _getAuthParams();

      // Викликаємо команду Objects для отримання реального списку ПРРО
      final response = await _apiClient.getObjects(authParams: authParams);

      // debugPrint('📥 [CASHALOT] Відповідь Objects:');
      // debugPrint('   ${const JsonEncoder.withIndent('   ').convert(response)}');

      final List<PrroInfo> result = [];

      // Парсимо складну структуру відповіді Cashalot
      // Структура: TaxObjects -> TransactionsRegistrars -> NumFiscal
      if (response['TaxObjects'] != null) {
        final taxObjects = response['TaxObjects'] as List?;
        if (taxObjects != null) {
          for (var taxObj in taxObjects) {
            if (taxObj is Map<String, dynamic>) {
              if (taxObj['TransactionsRegistrars'] != null) {
                final registrars = taxObj['TransactionsRegistrars'] as List?;
                if (registrars != null) {
                  for (var prro in registrars) {
                    if (prro is Map<String, dynamic>) {
                      try {
                        final prroInfo = PrroInfo.fromJson(prro);
                        result.add(prroInfo);
                        // debugPrint(
                        // '✅ [CASHALOT] ЗНАЙДЕНО ПРРО: ${prroInfo.name} -> ${prroInfo.numFiscal}',
                        // );
                      } catch (e) {
                        debugPrint('⚠️ [CASHALOT] Помилка парсингу ПРРО: $e');
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      if (result.isEmpty) {
        debugPrint('⚠️ [CASHALOT] ПРРО не знайдено в відповіді Objects');
        // Fallback: якщо є defaultPrroFiscalNum, повертаємо його
        final defaultPrro = defaultPrroFiscalNum;
        if (defaultPrro != null) {
          debugPrint(
            '📥 [CASHALOT] Використовується default ПРРО: $defaultPrro',
          );
          return [
            PrroInfo(numFiscal: defaultPrro, name: 'Каса за замовчуванням'),
          ];
        }
      } else {
        debugPrint('✅ [CASHALOT] Знайдено ${result.length} ПРРО');
      }

      return result;
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка getAvailablePrrosInfo: $e');
      // Fallback: якщо є defaultPrroFiscalNum, повертаємо його
      final defaultPrro = defaultPrroFiscalNum;
      if (defaultPrro != null) {
        debugPrint(
          '⚠️ [CASHALOT] Використовується default ПРРО через помилку: $defaultPrro',
        );
        return [
          PrroInfo(numFiscal: defaultPrro, name: 'Каса за замовчуванням'),
        ];
      }
      rethrow;
    }
  }

  @override
  Future<CashalotResponse> getPrroState({required int prroFiscalNum}) async {
    try {
      debugPrint('📡 [CASHALOT] Запит: getPrroState()');
      debugPrint('   ПРРО: $prroFiscalNum');

      final authParams = await _getAuthParams();
      final response = await _apiClient.getRegistrarState(
        prroFiscalNum: prroFiscalNum,
        authParams: authParams,
      );

      debugPrint('📥 [CASHALOT] Отримано відповідь getPrroState:');
      debugPrint('   ${const JsonEncoder.withIndent('   ').convert(response)}');

      // Перевіряємо наявність помилки в відповіді
      final errorCode = response['ErrorCode'] as String?;
      if (errorCode != null && errorCode.isNotEmpty) {
        final errorMessage =
            response['ErrorMessage'] as String? ?? 'Unknown error';
        debugPrint('❌ [CASHALOT] Помилка в getPrroState:');
        debugPrint('   ErrorCode: $errorCode');
        debugPrint('   ErrorMessage: $errorMessage');

        // Якщо це помилка синхронізації, спробуємо синхронізувати
        if (errorCode == 'InconsistentRegistrarState') {
          debugPrint(
            '🔄 [CASHALOT] Спроба синхронізації стану з AllLogs=true...',
          );
          try {
            final syncResponse = await _apiClient.getRegistrarState(
              prroFiscalNum: prroFiscalNum,
              authParams: authParams,
              allLogs: true, // Викачуємо всі події для синхронізації
            );

            // Перевіряємо чи після синхронізації все ще є помилка
            final syncErrorCode = syncResponse['ErrorCode'] as String?;
            if (syncErrorCode == null || syncErrorCode.isEmpty) {
              debugPrint('✅ [CASHALOT] Синхронізація успішна');
              return _parseResponse(syncResponse);
            } else {
              debugPrint(
                '⚠️ [CASHALOT] Після синхронізації все ще є помилка: $syncErrorCode',
              );
              // Після синхронізації все ще є помилка - просто логуємо
              debugPrint(
                '   ErrorMessage: ${syncResponse['ErrorMessage'] ?? 'Unknown'}',
              );
            }
          } catch (syncError) {
            debugPrint('❌ [CASHALOT] Помилка синхронізації: $syncError');
          }
        }

        return CashalotResponse(
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
      }

      // Логуємо стан зміни (0 - закрита, 1 - відкрита)
      final shiftState = response['ShiftState'] as int?;
      debugPrint('📊 [CASHALOT] Стан зміни (ShiftState): $shiftState');
      if (shiftState == 1) {
        debugPrint('   ✅ Зміна відкрита');
      } else {
        debugPrint('   ⚠️ Зміна закрита');
      }

      // Логуємо LastLocalNumber для синхронізації
      final lastLocalNumber = response['LastLocalNumber'] as int?;
      if (lastLocalNumber != null) {
        debugPrint('📋 [CASHALOT] Останній локальний номер: $lastLocalNumber');
        debugPrint('   Наступний номер має бути: ${lastLocalNumber + 1}');
      } else {
        debugPrint('⚠️ [CASHALOT] LastLocalNumber не знайдено в відповіді');
      }

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка отримання статусу: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  /// Синхронізує стан каси з сервером (викачує всі події)
  /// Використовується для виправлення помилки InconsistentRegistrarState
  Future<CashalotResponse> syncRegistrarState({
    required int prroFiscalNum,
  }) async {
    try {
      debugPrint('🔄 [CASHALOT] Синхронізація стану каси...');
      debugPrint('   ПРРО: $prroFiscalNum');

      final authParams = await _getAuthParams();
      final response = await _apiClient.getRegistrarState(
        prroFiscalNum: prroFiscalNum,
        authParams: authParams,
        allLogs: true, // Викачуємо всі події для синхронізації
      );

      debugPrint('✅ [CASHALOT] Синхронізація завершена');
      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка синхронізації: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  /// Парсер для помилки типу "Номер документа повинен дорівнювати 3683"
  /// ВАЖЛИВО: НЕ використовується для OfflineSessionId (це інше число!)
  int? _extractCorrectLocalNum(String errorMessage) {
    try {
      // Шукаємо число в кінці речення або після слів "дорівнювати"
      final regex = RegExp(r'дорівнювати\s*(\d+)');
      final match = regex.firstMatch(errorMessage);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    } catch (e) {
      debugPrint('⚠️ [CASHALOT] Помилка парсингу номера з тексту помилки: $e');
    }
    return null;
  }

  /// Отримує наступний локальний номер документа зі стану каси
  /// Повертає LastLocalNumber + 1 або null якщо не вдалося отримати
  /// Автоматично обробляє помилки синхронізації
  Future<int?> _getNextLocalNumber(int prroFiscalNum) async {
    try {
      final authParams = await _getAuthParams();

      // Спроба №1: Отримати стан з ПРИМУСОВИМ вимкненням офлайну
      // Це допоможе обійти InconsistentRegistrarState
      var response = await _apiClient.getRegistrarState(
        prroFiscalNum: prroFiscalNum,
        authParams: authParams,
        offline: false, // ГОВОРИМО СЕРВЕРУ, ЩО МИ В ОНЛАЙНІ
      );

      String? errorCode = response['ErrorCode'] as String?;
      String? errorMessage = response['ErrorMessage'] as String?;

      // ЛОГІКА ВИПРАВЛЕННЯ СИНХРОНІЗАЦІЇ
      if (errorCode == 'InconsistentRegistrarState') {
        debugPrint('🔄 [CASHALOT] Все ще бачимо розсинхрон. Спроба AllLogs...');

        response = await _apiClient.getRegistrarState(
          prroFiscalNum: prroFiscalNum,
          authParams: authParams,
          allLogs: true,
          offline: false,
        );

        errorCode = response['ErrorCode'] as String?;
        errorMessage = response['ErrorMessage'] as String?;
      }

      // ЛОГІКА ВИПРАВЛЕННЯ НЕПРАВИЛЬНОГО НОМЕРА
      // Це спрацює, якщо сервер поверне код 7 (CheckLocalNumberInvalid)
      if (errorCode == 'CheckLocalNumberInvalid' ||
          (errorMessage != null &&
              errorMessage.contains('повинен дорівнювати'))) {
        final correctNumber = _extractCorrectLocalNum(errorMessage ?? '');
        if (correctNumber != null) {
          debugPrint(
            '💡 [CASHALOT] Сервер підказав правильний номер: $correctNumber',
          );
          return correctNumber;
        }
      }

      // Якщо після всіх спроб є критична помилка
      if (errorCode != null && errorCode.isNotEmpty) {
        debugPrint(
          '❌ [CASHALOT] Критична помилка API: $errorCode - $errorMessage',
        );
        return null;
      }

      // СТАНДАРТНИЙ СЦЕНАРІЙ (після успішної відповіді)
      final lastLocalNumber = response['LastLocalNumber'] as int?;
      if (lastLocalNumber != null) {
        final nextNumber = lastLocalNumber + 1;
        debugPrint(
          '📋 [CASHALOT] Успішно отримано LastLocalNumber: $lastLocalNumber',
        );
        return nextNumber;
      }

      debugPrint('⚠️ [CASHALOT] LastLocalNumber відсутній у відповіді');
      return null;
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка отримання LastLocalNumber: $e');
      return null;
    }
  }

  @override
  Future<CashalotResponse> openShift({required int prroFiscalNum}) async {
    try {
      debugPrint('📡 [CASHALOT] Запит: openShift()');
      debugPrint('   Параметри:');
      debugPrint('     prroFiscalNum: $prroFiscalNum');

      final authParams = await _getAuthParams();

      final response = await _apiClient.openShift(
        prroFiscalNum: prroFiscalNum,
        authParams: authParams,
      );

      debugPrint('📥 [CASHALOT] Відповідь openShift:');
      debugPrint('   Дані: $response');

      final parsedResponse = _parseResponse(response);

      // Перевіряємо чи є помилка в відповіді
      if (!parsedResponse.isSuccess) {
        debugPrint('❌ [CASHALOT] openShift завершився з помилкою:');
        debugPrint('   ErrorCode: ${parsedResponse.errorCode}');
        debugPrint('   ErrorMessage: ${parsedResponse.errorMessage}');
        throw Exception(
          'Не вдалося відкрити зміну: ${parsedResponse.errorMessage ?? parsedResponse.errorCode ?? "Unknown error"}',
        );
      }

      return parsedResponse;
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка openShift: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  @override
  Future<CashalotResponse> registerSale({
    required int prroFiscalNum,
    required CheckPayload check,
    PosTransactionResult? cardData,
  }) async {
    try {
      debugPrint('📡 [CASHALOT] Запит: registerSale()');
      debugPrint('   Сума: ${check.checkTotal.sum}');

      final authParams = await _getAuthParams();

      // 1. Формуємо CHECKBODY (Товари)
      final checkBody = check.checkBody.map((item) {
        // Важливо: COST = PRICE * AMOUNT
        final cost = item.price * item.amount;

        return {
          "CODE": item.code,
          "NAME": item.name,
          "AMOUNT": item.amount,
          "PRICE": item.price,
          // Округляємо вартість до 2 знаків, щоб сервер прийняв математику
          "COST": double.parse(cost.toStringAsFixed(2)),
          // "LETTERS": "A", // Розкоментуйте, якщо ви платник ПДВ
          // "UKTZED": item.uktzed, // Додайте, якщо є підакцизні товари
        };
      }).toList();

      // 2. Формуємо CHECKPAY (Оплата)
      final checkPay = check.checkPay.map((p) {
        return {
          "PAYFORMNM": p.payFormNm, // "ГОТІВКА" або "КАРТКА"
          "SUM": double.parse(p.sum.toStringAsFixed(2)),
        };
      }).toList();

      // 3. Збираємо повний об'єкт "Check"
      // Ключі обов'язково UPPERCASE згідно з документацією
      final checkData = {
        "CHECKHEAD": {
          "DOCTYPE": "SaleGoods",
          "DOCSUBTYPE": "CheckGoods",
          "CASHIER": check.checkHead.cashier,
          // "COMMENT": "Коментар..."
        },
        "CHECKTOTAL": {
          "SUM": double.parse(check.checkTotal.sum.toStringAsFixed(2)),
        },
        "CHECKPAY": checkPay,
        "CHECKBODY": checkBody,
        // "CHECKTAX": [], // Додайте, якщо потрібно передавати податки
      };

      debugPrint('📦 [CASHALOT] JSON тіло для відправки:');
      // debugPrint(const JsonEncoder.withIndent('  ').convert(checkData));

      // 4. Відправляємо запит
      // Ми не передаємо NumLocal, бо сервер сам його призначить
      final response = await _apiClient.registerCheck(
        prroFiscalNum: prroFiscalNum,
        checkData: checkData, // Передаємо готовий об'єкт
        authParams: authParams,
        autoOpenShift: true, // Авто-відкриття зміни (дуже зручно)
      );

      debugPrint('📥 [CASHALOT] Відповідь registerSale: $response');

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка registerSale: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  @override
  Future<CashalotResponse> serviceDeposit({
    required int prroFiscalNum,
    required double amount,
    required String cashier,
  }) async {
    try {
      debugPrint('📡 [CASHALOT] Запит: serviceDeposit()');
      debugPrint('   Сума: $amount, Касир: $cashier');

      final authParams = await _getAuthParams();

      final checkHead = {
        'DOCTYPE': 'SaleGoods',
        'DOCSUBTYPE': 'ServiceDeposit',
      };

      final checkTotal = {'SUM': amount};

      // 4. Відправляємо запит
      // Увага: checkBody та checkPay передаємо пустими або null,
      // бо для внесення вони не потрібні (гроші просто кладуться в скриньку)
      final response = await _apiClient.registerDeposit(
        prroFiscalNum: prroFiscalNum,
        checkHead: checkHead,
        checkBody: [], // Товарів немає
        checkTotal: checkTotal,
        checkPay: [], // Оплати немає (це внутрішня операція)
        authParams: authParams,
        offline: false,
      );

      debugPrint('📥 [CASHALOT] Результат: $response');
      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка: $e');
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
      debugPrint('📡 [CASHALOT] Запит: serviceIssue()');
      debugPrint('   Сума: $amount, Касир: $cashier');

      // 1. Перевірка стану зміни
      // final stateResponse = await getPrroState(prroFiscalNum: prroFiscalNum);
      // if (!stateResponse.isSuccess) {
      //   return CashalotResponse(
      //     errorCode: stateResponse.errorCode ?? 'ERROR',
      //     errorMessage:
      //         'Не вдалося перевірити стан каси: ${stateResponse.errorMessage}',
      //   );
      // }

      // if (stateResponse.shiftState != 1) {
      //   return CashalotResponse(
      //     errorCode: 'SHIFT_NOT_OPEN',
      //     errorMessage:
      //         'Зміна не відкрита. Неможливо виконати службову видачу.',
      //   );
      // }

      // 2. Отримання ключів та номера чека
      final authParams = await _getAuthParams();

      final checkData = {
        "CHECKHEAD": {"DOCTYPE": "SaleGoods", "DOCSUBTYPE": "ServiceIssue"},
        "CHECKTOTAL": {"SUM": double.parse(amount.toStringAsFixed(2))},
      };

      final response = await _apiClient.registerCheck(
        prroFiscalNum: prroFiscalNum,
        checkData: checkData,
        authParams: authParams,
        offline: false,
      );

      debugPrint('📥 [CASHALOT] Відповідь serviceIssue: $response');

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка serviceIssue: $e');
      return CashalotResponse(
        errorCode: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<CashalotResponse> printXReport({required int prroFiscalNum}) async {
    try {
      debugPrint('📡 [CASHALOT] Запит: printXReport()');
      debugPrint('   Параметри:');
      debugPrint('     prroFiscalNum: $prroFiscalNum');

      final authParams = await _getAuthParams();

      final response = await _apiClient.printXReport(
        prroFiscalNum: prroFiscalNum,
        authParams: authParams,
      );

      debugPrint('📥 [CASHALOT] Відповідь printXReport:');
      debugPrint('   Дані: $response');

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка printXReport: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  @override
  Future<CashalotResponse> closeShift({required int prroFiscalNum}) async {
    try {
      debugPrint('📡 [CASHALOT] Запит: closeShift()');
      debugPrint('   Параметри:');
      debugPrint('     prroFiscalNum: $prroFiscalNum');

      final authParams = await _getAuthParams();

      final response = await _apiClient.closeShift(
        prroFiscalNum: prroFiscalNum,
        authParams: authParams,
      );

      debugPrint('📥 [CASHALOT] Відповідь closeShift:');
      debugPrint('   Дані: $response');

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка closeShift: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  /// Приведення локального стану ПРРО у відповідність до стану на сервері
  /// Документація: стор. 17
  Future<CashalotResponse> cleanupCashalot({required int prroFiscalNum}) async {
    final response = await _apiClient.cleanup(
      prroFiscalNum: prroFiscalNum,
      authParams: await _getAuthParams(),
    );

    return _parseResponse(response);
  }

  @override
  Future<PrroInfo> getPrroInfo({required int prroFiscalNum}) async {
    final response = await _apiClient.getRegistrarState(
      prroFiscalNum: prroFiscalNum,
      authParams: await _getAuthParams(),
    );
    return PrroInfo.fromJson(response);
  }

  /// Парсить відповідь API в CashalotResponse
  CashalotResponse _parseResponse(Map<String, dynamic> response) {
    final errorCode = response['ErrorCode'] as String?;
    final errorMessage = response['ErrorMessage'] as String?;

    final numFiscal =
        response['NumFiscal'] as String? ??
        response['num_fiscal'] as String? ??
        response['fiscal_number'] as String? ??
        response['id']?.toString();

    final qrCode =
        response['QRCode'] as String? ??
        response['qr_code'] as String? ??
        response['qrCode'] as String?;

    final visualization =
        response['Visualization'] as String? ??
        response['visualization'] as String?;

    final shiftState = response['ShiftState'] as int?;

    // --- ПАРСИНГ НОВИХ ПОЛІВ ---

    // 1. ShiftOpened (Дата відкриття зміни)
    DateTime? shiftOpened;
    if (response['ShiftOpened'] != null) {
      try {
        shiftOpened = DateTime.parse(response['ShiftOpened'].toString());
      } catch (e) {
        debugPrint('⚠️ Помилка парсингу дати ShiftOpened: $e');
      }
    }

    // 2. Службові суми (знаходяться глибоко в Totals -> ZREPBODY)
    double? serviceInput;
    double? serviceOutput;

    if (response['Totals'] != null && response['Totals'] is Map) {
      final totals = response['Totals'] as Map<String, dynamic>;

      if (totals['ZREPBODY'] != null && totals['ZREPBODY'] is Map) {
        final body = totals['ZREPBODY'] as Map<String, dynamic>;

        // Безпечно парсимо double (може прийти int або string)
        serviceInput = double.tryParse(body['SERVICEINPUT']?.toString() ?? '');
        serviceOutput = double.tryParse(
          body['SERVICEOUTPUT']?.toString() ?? '',
        );
      }
    }

    // --- ВИПРАВЛЕНА ЛОГІКА ПОМИЛОК ---
    if (errorCode != null && errorCode.isNotEmpty && errorCode != 'Ok') {
      return CashalotResponse(
        errorCode: errorCode,
        errorMessage: errorMessage ?? 'Unknown error',
        numFiscal: numFiscal,
        qrCode: qrCode,
        visualization: visualization,
        shiftState: shiftState,
        shiftOpened: shiftOpened,
        serviceInput: serviceInput,
        serviceOutput: serviceOutput,
      );
    }

    return CashalotResponse(
      errorCode: null, // Успіх
      errorMessage: errorMessage,
      numFiscal: numFiscal,
      qrCode: qrCode,
      visualization: visualization,
      shiftState: shiftState,
      shiftOpened: shiftOpened,
      serviceInput: serviceInput,
      serviceOutput: serviceOutput,
    );
  }
}
