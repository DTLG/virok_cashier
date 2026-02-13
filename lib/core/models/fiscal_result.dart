import 'vchasno_errors.dart';

/// Результат фіскалізації чека
class FiscalResult {
  final bool success;
  final String message;
  final String? qrUrl;
  final String? docNumber; // Номер чека для відображення
  final double? totalAmount; // Сума чека
  final VchasnoException? error; // Помилка, якщо є

  FiscalResult({
    required this.success,
    required this.message,
    this.qrUrl,
    this.docNumber,
    this.totalAmount,
    this.error,
  });

  /// Створює успішний результат
  factory FiscalResult.success({
    required String message,
    String? qrUrl,
    String? docNumber,
    double? totalAmount,
  }) {
    return FiscalResult(
      success: true,
      message: message,
      qrUrl: qrUrl,
      docNumber: docNumber,
      totalAmount: totalAmount,
    );
  }

  /// Створює результат з помилкою
  factory FiscalResult.failure({
    required String message,
    VchasnoException? error,
  }) {
    return FiscalResult(
      success: false,
      message: message,
      error: error,
    );
  }
}

