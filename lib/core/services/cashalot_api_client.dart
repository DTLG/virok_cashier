import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cashalot_token_storage.dart';

class CashalotApiClient {
  final String baseUrl; // e.g., https://fsapi.cashalot.org.ua
  final Duration timeout;
  final CashalotTokenStorage? tokenStorage;

  CashalotApiClient({
    required this.baseUrl,
    CashalotTokenStorage? tokenStorage,
    this.timeout = const Duration(seconds: 20),
  }) : tokenStorage = tokenStorage;

  // Authentication
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login');
    final response = await http
        .post(
          uri,
          headers: _jsonHeaders(),
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(timeout);

    _ensureSuccess(response, 'Login failed');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final access = body['access_token'] as String?;
    final refresh = body['refresh_token'] as String?;
    final expiresIn = body['expires_in'] as int?;

    if (access == null || refresh == null) {
      throw Exception('Invalid login response');
    }

    final expiry = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    await tokenStorage?.saveTokens(
      accessToken: access,
      refreshToken: refresh,
      accessTokenExpiry: expiry,
    );
  }

  Future<void> refreshToken() async {
    if (tokenStorage == null) {
      throw Exception('TokenStorage required for token refresh');
    }
    final refresh = await tokenStorage!.getRefreshToken();
    if (refresh == null) throw Exception('No refresh token');

    final uri = Uri.parse('$baseUrl/refresh');
    final response = await http
        .post(
          uri,
          headers: _jsonHeaders(),
          body: jsonEncode({'refresh_token': refresh}),
        )
        .timeout(timeout);

    _ensureSuccess(response, 'Refresh token failed');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final access = body['access_token'] as String?;
    final newRefresh = body['refresh_token'] as String? ?? refresh;
    final expiresIn = body['expires_in'] as int?;

    if (access == null) throw Exception('Invalid refresh response');

    final expiry = expiresIn != null
        ? DateTime.now().add(Duration(seconds: expiresIn))
        : null;

    await tokenStorage?.saveTokens(
      accessToken: access,
      refreshToken: newRefresh,
      accessTokenExpiry: expiry,
    );
  }

  // Status
  /// Отримання стану ПРРО (TransactionsRegistrarState)
  /// Обов'язковий виклик перед будь-якими операціями
  /// [allLogs] - якщо true, викачує всі останні події з сервера для синхронізації
  /// Отримання стану ПРРО (TransactionsRegistrarState)

  Future<Map<String, dynamic>> getPrroInfo({
    required int prroFiscalNum,
    required Map<String, dynamic> authParams,
  }) async {
    final payload = {'Command': 'Objects'};
    return _postWithKeys('', payload);
  }

  Future<Map<String, dynamic>> getRegistrarState({
    required int prroFiscalNum,
    required Map<String, dynamic> authParams,
    bool allLogs = false,
    bool offline = false, // Додаємо цей параметр
  }) async {
    final payload = {
      'Command': 'TransactionsRegistrarState',
      'NumFiscal': prroFiscalNum,
      'AllLogs': true,
      'Offline': offline, // Передаємо статус офлайну
      ...authParams,
    };
    return _postWithKeys('', payload);
  }

  /// Приведення локального стану ПРРО у відповідність до стану на сервері
  /// Документація: стор. 17
  Future<Map<String, dynamic>> cleanup({
    required int prroFiscalNum,
    required Map<String, dynamic> authParams,
    bool remove = false, // За замовчуванням false (просто синхронізація)
    bool visualization = true, // Отримати Z-звіт, якщо зміна закриється
  }) async {
    final payload = {
      'Command': 'Cleanup',
      'NumFiscal': prroFiscalNum,
      'Remove': remove,
      'Visualization': visualization,
      ...authParams,
    };

    // _postWithKeys - ваш метод відправки запиту
    return _postWithKeys('', payload);
  }

  // Info
  /// Отримання списку доступних об'єктів (Objects)
  /// Повертає всі ПРРО, доступні для даного ключа
  Future<Map<String, dynamic>> getObjects({
    required Map<String, dynamic> authParams,
  }) async {
    final payload = {'Command': 'Objects', ...authParams};
    return _postWithKeys('', payload);
  }

  // Shifts
  /// Відкриття зміни
  /// [numLocal] - локальний номер документа (обов'язковий для синхронізації)
  /// [offline] - чи використовувати офлайн-режим (за замовчуванням false)
  Future<Map<String, dynamic>> openShift({
    required int prroFiscalNum,
    required Map<String, dynamic> authParams,
    bool offline = false,
  }) async {
    final payload = {
      'Command': 'OpenShift',
      'NumFiscal': prroFiscalNum, // Передаємо як int
      ...authParams, // Certificate, PrivateKey, Password
    };
    return _postWithKeys('', payload);
  }

  /// Закриття зміни (Z-звіт)
  Future<Map<String, dynamic>> closeShift({
    required int prroFiscalNum,
    required Map<String, dynamic> authParams,
  }) async {
    final payload = {
      'Command': 'CloseShift',
      'ZRepAuto': true,
      "Visualization": true,
      'NumFiscal': prroFiscalNum, // Передаємо як int
      ...authParams, // Certificate, PrivateKey, Password
    };
    return _postWithKeys('', payload);
  }

  Future<Map<String, dynamic>> printXReport({
    required int prroFiscalNum,
    required Map<String, dynamic> authParams,
  }) async {
    {}

    final payload = {
      'Command': 'LastShiftTotals',
      'NumFiscal': prroFiscalNum, // Передаємо як int
      "Visualization": true,
      ...authParams, // Certificate, PrivateKey, Password
    };
    return _postWithKeys('', payload);
  }

  // Receipts
  /// Реєстрація чека згідно з документацією Cashalot
  /// [numLocal] - локальний номер документа (обов'язковий для синхронізації)
  /// [offline] - чи використовувати офлайн-режим (за замовчуванням false)
  Future<Map<String, dynamic>> registerDeposit({
    required int prroFiscalNum,
    required Map<String, dynamic> checkHead,
    required List<Map<String, dynamic>> checkBody,
    required Map<String, dynamic> checkTotal,
    required List<Map<String, dynamic>> checkPay,
    required Map<String, dynamic> authParams,
    bool offline = false,
  }) async {
    final payload = {
      'Command': 'RegisterCheck',
      'NumFiscal': prroFiscalNum, // Передаємо як int
      ...authParams, // Certificate, PrivateKey, Password
      'Check': {'CHECKHEAD': checkHead, 'CHECKTOTAL': checkTotal},
      'Visualization': true,
    };
    return _postWithKeys('', payload);
  }

  Future<Map<String, dynamic>> registerCheck({
    required int prroFiscalNum,
    required Map<String, dynamic> checkData, // <--- Приймає Map
    required Map<String, dynamic> authParams,
    bool autoOpenShift = true,
    bool getQrCode = true,
    bool visualization = true,
    bool offline = false,
  }) async {
    final payload = {
      "Command": "RegisterCheck",
      "NumFiscal": prroFiscalNum,
      "Check": checkData, // <--- Вставляє його сюди
      "AutoOpenShift": autoOpenShift,
      "GetQrCode": getQrCode,
      "Visualization": visualization,
      ...authParams,
    };
    return _postWithKeys('', payload);
  }

  // Старий метод для сумісності (можна видалити пізніше)
  Future<Map<String, dynamic>> sellReceipt({
    required String cashierName,
    required List<Map<String, dynamic>> items,
    required String paymentMethod, // e.g., 'CASH' or 'CARD'
    double? amountPaid,
  }) async {
    final payload = {
      'cashier': cashierName,
      'items': items,
      'payment_method': paymentMethod,
      if (amountPaid != null) 'amount_paid': amountPaid,
    };
    return _authorizedPost('/receipts/sell', payload);
  }

  Future<Map<String, dynamic>> returnReceipt({
    required String originalReceiptId,
    required String cashierName,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'original_receipt_id': originalReceiptId,
      'cashier': cashierName,
      'items': items,
    };
    return _authorizedPost('/receipts/return', payload);
  }

  Future<Map<String, dynamic>> receiptStatus({required String receiptId}) {
    return _authorizedPost('/receipts/status', {'receipt_id': receiptId});
  }

  // Info
  Future<Map<String, dynamic>> me() async {
    return _authorizedPost('/me', {});
  }

  Future<Map<String, dynamic>> listShifts({int? page, int? pageSize}) async {
    return _authorizedPost('/shifts', {
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    });
  }

  Future<Map<String, dynamic>> listReceipts({int? page, int? pageSize}) async {
    return _authorizedPost('/receipts', {
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    });
  }

  // Helpers
  Map<String, String> _jsonHeaders({String? token}) {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ЯДЕРНИЙ СКИНУТИ (Cleanup)
  // Використовується при помилці InconsistentRegistrarState
  Future<Map<String, dynamic>> cleanupPrro({
    required int prroFiscalNum,
    required Map<String, dynamic> authParams,
  }) async {
    final payload = {
      'Command': 'Cleanup',
      'NumFiscal': prroFiscalNum, // Каса, яку треба "полікувати"
      ...authParams,
    };
    return _postWithKeys('', payload);
  }

  /// POST запит з ключами (без токенів)
  Future<Map<String, dynamic>> _postWithKeys(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    print('📡 [DEBUG] Відправка на URL: $uri');
    final response = await http
        .post(
          uri,
          headers: _jsonHeaders(), // Без токена
          body: jsonEncode(body),
        )
        .timeout(timeout);

    // Перевіряємо чи відповідь не порожня
    if (response.body.isEmpty || response.body.trim().isEmpty) {
      throw Exception(
        'Request failed: HTTP ${response.statusCode} - Empty response body',
      );
    }

    _ensureSuccess(response, 'Request failed');

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
        'Unable to parse JSON message: ${e.toString()}\nResponse body: ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> _authorizedPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    // Цей метод використовується для старих endpoint з токенами
    // Для нових endpoint з ключами використовується _postWithKeys
    if (tokenStorage == null) {
      throw Exception('TokenStorage required for authorized requests');
    }

    var access = await tokenStorage!.getAccessToken();
    final expiry = await tokenStorage!.getAccessTokenExpiry();

    if (access == null || (expiry != null && DateTime.now().isAfter(expiry))) {
      await refreshToken();
      access = await tokenStorage!.getAccessToken();
    }
    if (access == null) throw Exception('No access token');

    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(
          uri,
          headers: _jsonHeaders(token: access),
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (response.statusCode == 401) {
      // try refresh once
      await refreshToken();
      final newAccess = await tokenStorage!.getAccessToken();
      if (newAccess == null) throw Exception('Unauthorized');
      final retry = await http
          .post(
            uri,
            headers: _jsonHeaders(token: newAccess),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      _ensureSuccess(retry, 'Request failed');
      return jsonDecode(retry.body) as Map<String, dynamic>;
    }

    _ensureSuccess(response, 'Request failed');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _ensureSuccess(http.Response response, String fallback) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        '$fallback: HTTP ${response.statusCode} ${response.reasonPhrase}\n${response.body}',
      );
    }
  }
}
