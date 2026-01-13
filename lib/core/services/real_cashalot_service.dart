import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import '../models/cashalot_models.dart';
import '../models/prro_info.dart';
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
  Future<List<String>> getAvailablePrros() async {
    try {
      debugPrint('📡 [CASHALOT] Запит: getAvailablePrros()');
      debugPrint('🔍 Шукаємо доступні ПРРО для вашого ключа...');

      final authParams = await _getAuthParams();

      // Викликаємо команду Objects для отримання реального списку ПРРО
      final response = await _apiClient.getObjects(authParams: authParams);

      debugPrint('📥 [CASHALOT] Відповідь Objects:');
      debugPrint('   ${const JsonEncoder.withIndent('   ').convert(response)}');

      final List<String> result = [];

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
                        result.add(numFiscalStr);
                        final name = prro['Name'] as String? ?? 'Без назви';
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
          return [defaultPrro];
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
        return [defaultPrro];
      }
      rethrow;
    }
  }

  @override
  Future<List<PrroInfo>> getAvailablePrrosInfo() async {
    try {
      debugPrint('📡 [CASHALOT] Запит: getAvailablePrrosInfo()');
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
                      try {
                        final prroInfo = PrroInfo.fromJson(prro);
                        result.add(prroInfo);
                        debugPrint(
                          '✅ [CASHALOT] ЗНАЙДЕНО ПРРО: ${prroInfo.name} -> ${prroInfo.numFiscal}',
                        );
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

      // Логуємо стан зміни (0 - закрита, 1 - відкрита)
      final shiftState = response['ShiftState'] as int?;
      debugPrint('📊 [CASHALOT] Стан зміни (ShiftState): $shiftState');
      if (shiftState == 1) {
        debugPrint('   ✅ Зміна відкрита');
      } else {
        debugPrint('   ⚠️ Зміна закрита');
      }

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка отримання статусу: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
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

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка openShift: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
    }
  }

  @override
  Future<CashalotResponse> registerSale({
    required int prroFiscalNum,
    required CheckPayload check,
  }) async {
    try {
      debugPrint('📡 [CASHALOT] Запит: registerSale()');
      debugPrint('   Параметри:');
      debugPrint('     prroFiscalNum: $prroFiscalNum');
      debugPrint('   Тіло запиту (CheckPayload):');
      debugPrint('     Касир: ${check.checkHead.cashier}');
      debugPrint('     Тип документа: ${check.checkHead.docType}');
      debugPrint('     Підтип: ${check.checkHead.docSubType}');
      debugPrint('     Сума: ${check.checkTotal.sum} UAH');
      debugPrint('     Товарів: ${check.checkBody.length}');
      debugPrint(
        '     Метод оплати: ${check.checkPay.map((p) => '${p.payFormNm} ${p.sum}').join(', ')}',
      );
      debugPrint('   JSON тіло:');
      debugPrint(const JsonEncoder.withIndent('     ').convert(check.toJson()));

      final authParams = await _getAuthParams();

      // Конвертуємо CheckPayload в формат для API
      // Згідно з документацією, потрібно передавати структуру чека
      final items = check.checkBody
          .map(
            (item) => {
              'CODE': item.code,
              'NAME': item.name,
              'AMOUNT': item.amount,
              'PRICE': item.price,
              'COST': item.cost,
              'LETTERS': 'A', // Податкова група (за замовчуванням)
              'UKTZED': '', // Код УКТЗЕД (якщо є)
            },
          )
          .toList();

      final response = await _apiClient.registerCheck(
        prroFiscalNum: prroFiscalNum,
        checkHead: check.checkHead.toJson(),
        checkBody: items,
        checkTotal: check.checkTotal.toJson(),
        checkPay: check.checkPay.map((p) => p.toJson()).toList(),
        authParams: authParams,
      );

      debugPrint('📥 [CASHALOT] Відповідь registerSale:');
      debugPrint('   Дані: $response');

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
      debugPrint('   Параметри:');
      debugPrint('     prroFiscalNum: $prroFiscalNum');
      debugPrint('     amount: $amount UAH');
      debugPrint('     cashier: $cashier');

      final authParams = await _getAuthParams();

      // Створюємо чек для службового внесення
      final items = [
        {
          'CODE': 'SERVICE_DEPOSIT',
          'NAME': 'Службове внесення',
          'AMOUNT': 1.0,
          'PRICE': amount,
          'COST': amount,
          'LETTERS': 'A',
          'UKTZED': '',
        },
      ];

      final checkHead = {
        'DOCTYPE': 'ServiceDeposit',
        'DOCSUBTYPE': 'ServiceDeposit',
        'CASHIER': cashier,
      };

      final checkTotal = {'SUM': amount};

      final checkPay = [
        {'PAYFORMNM': 'ГОТІВКА', 'SUM': amount},
      ];

      final response = await _apiClient.registerCheck(
        prroFiscalNum: prroFiscalNum,
        checkHead: checkHead,
        checkBody: items,
        checkTotal: checkTotal,
        checkPay: checkPay,
        authParams: authParams,
      );

      debugPrint('📥 [CASHALOT] Відповідь serviceDeposit:');
      debugPrint('   Дані: $response');

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка serviceDeposit: $e');
      return CashalotResponse(errorCode: 'ERROR', errorMessage: e.toString());
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
      debugPrint('   Параметри:');
      debugPrint('     prroFiscalNum: $prroFiscalNum');
      debugPrint('     amount: $amount UAH');
      debugPrint('     cashier: $cashier');

      final authParams = await _getAuthParams();

      // Створюємо чек для службової видачі
      final items = [
        {
          'CODE': 'SERVICE_ISSUE',
          'NAME': 'Службова видача',
          'AMOUNT': 1.0,
          'PRICE': amount,
          'COST': amount,
          'LETTERS': 'A',
          'UKTZED': '',
        },
      ];

      final checkHead = {
        'DOCTYPE': 'ServiceIssue',
        'DOCSUBTYPE': 'ServiceIssue',
        'CASHIER': cashier,
      };

      final checkTotal = {'SUM': amount};

      final checkPay = [
        {'PAYFORMNM': 'ГОТІВКА', 'SUM': amount},
      ];

      final response = await _apiClient.registerCheck(
        prroFiscalNum: prroFiscalNum,
        checkHead: checkHead,
        checkBody: items,
        checkTotal: checkTotal,
        checkPay: checkPay,
        authParams: authParams,
      );

      debugPrint('📥 [CASHALOT] Відповідь serviceIssue:');
      debugPrint('   Дані: $response');

      return _parseResponse(response);
    } catch (e) {
      debugPrint('❌ [CASHALOT] Помилка serviceIssue: $e');
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

  /// Парсить відповідь API в CashalotResponse
  CashalotResponse _parseResponse(Map<String, dynamic> response) {
    // Припускаємо, що API повертає дані в такому форматі:
    // {
    //   "ErrorCode": "...",
    //   "ErrorMessage": "...",
    //   "NumFiscal": "...",
    //   "QRCode": "...",
    //   "Visualization": "...",
    // }

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

    // Якщо є ErrorCode (навіть якщо він порожній), вважаємо це помилкою
    if (errorCode != null && errorCode.isNotEmpty) {
      return CashalotResponse(
        errorCode: errorCode,
        errorMessage: errorMessage ?? 'Unknown error',
        numFiscal: numFiscal,
        qrCode: qrCode,
        visualization: visualization,
        shiftState: shiftState,
      );
    }

    return CashalotResponse(
      errorCode: null, // Успіх
      errorMessage: errorMessage,
      numFiscal: numFiscal,
      qrCode: qrCode,
      visualization: visualization,
      shiftState: shiftState,
    );
  }
}
