class PosTransactionResult {
  final bool isSuccess;
  final String? errorMessage;

  /// Дані для банківського чека (вимагає податкова)
  final String? rrn; // Reference Retrieval Number
  final String? authCode; // Approval Code
  final String? terminalId; // ID термінала
  final String? cardPan; // Маскований номер картки (4111 **** **** 1111)
  final String? paymentSystem; // VISA / MASTERCARD
  final String? acquireName; // Назва банку-еквайра
  final String? transactionDate; // Дата транзакції (рядок у форматі термінала)

  const PosTransactionResult({
    required this.isSuccess,
    this.errorMessage,
    this.rrn,
    this.authCode,
    this.terminalId,
    this.cardPan,
    this.paymentSystem,
    this.acquireName,
    this.transactionDate,
  });
}

