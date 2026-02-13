import 'dart:async';
import 'dart:io';

/// Типи помилок Vchasno
enum VchasnoErrorType {
  /// Немає зв'язку з Device Manager (SocketException/TimeoutException)
  noConnection,

  /// Зміна закрита - потрібно відкрити зміну
  shiftClosed,

  /// Зміна триває більше 24 годин - потрібен Z-звіт
  shiftTooLong,

  /// Закінчився папір
  noPaper,

  /// Помилка валідації (1016)
  validationError,

  /// Збій інтернету під час чека
  networkTimeout,

  /// Інша помилка
  unknown,
}

/// Клас помилки Vchasno з детальною інформацією
class VchasnoException implements Exception {
  final VchasnoErrorType type;
  final String message;
  final int? errorCode;
  final int? resAction;
  final Map<String, dynamic>? responseData;
  final String? requestJson;

  VchasnoException({
    required this.type,
    required this.message,
    this.errorCode,
    this.resAction,
    this.responseData,
    this.requestJson,
  });

  @override
  String toString() => message;

  /// Перевіряє чи можна повторити операцію
  bool get canRetry {
    switch (type) {
      case VchasnoErrorType.noConnection:
      case VchasnoErrorType.networkTimeout:
        return true;
      case VchasnoErrorType.shiftClosed:
        return true; // Після відкриття зміни
      case VchasnoErrorType.shiftTooLong:
      case VchasnoErrorType.noPaper:
      case VchasnoErrorType.validationError:
      case VchasnoErrorType.unknown:
        return resAction == 1; // res_action = 1 означає можна повторити
    }
  }

  /// Перевіряє чи потрібна колізія (res_action = 2)
  bool get needsCollisionFix => resAction == 2;

  /// Створює помилку з відповіді API
  factory VchasnoException.fromResponse(
    Map<String, dynamic> response,
    String? requestJson,
  ) {
    final res = response['res'] as int? ?? -1;
    final errorText = response['errortxt'] as String? ??
        response['err_txt'] as String? ??
        'Невідома помилка';
    final resAction = response['res_action'] as int?;
    final warnings = response['warnings'] as List?;

    // Перевірка warnings
    if (warnings != null) {
      for (final warning in warnings) {
        final code = warning['code'] as int?;
        if (code == 3003) {
          // Зміна відкрита більше 24 годин
          return VchasnoException(
            type: VchasnoErrorType.shiftTooLong,
            message: warning['wtxt'] as String? ??
                'Поточна зміна відкрита більше 24 годин тому',
            errorCode: res,
            resAction: resAction,
            responseData: response,
            requestJson: requestJson,
          );
        }
      }
    }

    // Перевірка коду помилки
    if (res == 1016) {
      return VchasnoException(
        type: VchasnoErrorType.validationError,
        message: errorText,
        errorCode: res,
        resAction: resAction,
        responseData: response,
        requestJson: requestJson,
      );
    }

    // Перевірка тексту помилки на закриту зміну
    final errorLower = errorText.toLowerCase();
    if (errorLower.contains('змін') ||
        errorLower.contains('shift') ||
        errorLower.contains('закрит')) {
      return VchasnoException(
        type: VchasnoErrorType.shiftClosed,
        message: errorText,
        errorCode: res,
        resAction: resAction,
        responseData: response,
        requestJson: requestJson,
      );
    }

    // Перевірка на папір
    if (errorLower.contains('папір') ||
        errorLower.contains('paper') ||
        errorLower.contains('принтер')) {
      return VchasnoException(
        type: VchasnoErrorType.noPaper,
        message: errorText,
        errorCode: res,
        resAction: resAction,
        responseData: response,
        requestJson: requestJson,
      );
    }

    return VchasnoException(
      type: VchasnoErrorType.unknown,
      message: errorText,
      errorCode: res,
      resAction: resAction,
      responseData: response,
      requestJson: requestJson,
    );
  }

  /// Створює помилку з винятку
  factory VchasnoException.fromException(
    dynamic exception,
    String? requestJson,
  ) {
    if (exception is SocketException || exception is TimeoutException) {
      return VchasnoException(
        type: VchasnoErrorType.noConnection,
        message: 'Немає зв\'язку з Device Manager. Перевірте, чи запущено '
            '\'Вчасно.Каса\' і чи є інтернет.',
        requestJson: requestJson,
      );
    }

    if (exception is TimeoutException) {
      return VchasnoException(
        type: VchasnoErrorType.networkTimeout,
        message: 'Таймаут з\'єднання. Чек може бути відправлено, але відповідь '
            'не прийшла. Перевірте статус останнього чека перед повторною спробою.',
        requestJson: requestJson,
      );
    }

    return VchasnoException(
      type: VchasnoErrorType.unknown,
      message: exception.toString(),
      requestJson: requestJson,
    );
  }
}

