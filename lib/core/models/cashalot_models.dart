/// Моделі даних для роботи з Cashalot API
/// Відповідають JSON-структурі з документації Cashalot

/// Базовий клас відповіді від сервера Cashalot
class CashalotResponse {
  final String? errorCode;
  final String? errorMessage;
  final String? numFiscal; // Фіскальний номер документа
  final String? qrCode; // Base64 зображення QR
  final String? visualization; // Текстовий вигляд чека
  final int? shiftState; // Стан зміни: 0 - закрита, 1 - відкрита

  // Нові поля
  final DateTime? shiftOpened; // Час відкриття зміни
  final double? serviceInput; // Службове внесення
  final double? serviceOutput; // Службова видача (за компанію додамо і це)

  CashalotResponse({
    this.errorCode,
    this.errorMessage,
    this.numFiscal,
    this.qrCode,
    this.visualization,
    this.shiftState,
    this.shiftOpened,
    this.serviceInput,
    this.serviceOutput,
  });

  bool get isSuccess => errorCode == null || errorCode == 'Ok';

  /// Чи відкрита зміна
  bool get isShiftOpen => shiftState == 1;
}

/// Модель чека (спрощена)
class CheckPayload {
  final CheckHead checkHead;
  final CheckTotal checkTotal;
  final List<CheckBodyRow> checkBody;
  final List<CheckPayRow> checkPay;

  CheckPayload({
    required this.checkHead,
    required this.checkTotal,
    required this.checkBody,
    required this.checkPay,
  });

  Map<String, dynamic> toJson() => {
    "CHECKHEAD": checkHead.toJson(),
    "CHECKTOTAL": checkTotal.toJson(),
    "CHECKBODY": checkBody.map((e) => e.toJson()).toList(),
    "CHECKPAY": checkPay.map((e) => e.toJson()).toList(),
  };
}

/// Заголовок чека
class CheckHead {
  final String docType; // "SaleGoods", "ServiceDeposit", "ServiceIssue"
  final String docSubType; // "CheckGoods", "ServiceDeposit", "ServiceIssue"
  final String cashier;

  CheckHead({
    this.docType = "SaleGoods",
    this.docSubType = "CheckGoods",
    required this.cashier,
  });

  Map<String, dynamic> toJson() => {
    "DOCTYPE": docType,
    "DOCSUBTYPE": docSubType,
    "CASHIER": cashier,
  };
}

/// Рядок товару в чеку
class CheckBodyRow {
  final String code;
  final String name;
  final double amount;
  final double price;
  final double cost; // amount * price
  final String? uktzeds; // УКТЗЕД код

  CheckBodyRow({
    required this.code,
    required this.name,
    required this.amount,
    required this.price,
    this.uktzeds,
  }) : cost = amount * price;

  Map<String, dynamic> toJson() => {
    "CODE": code,
    "NAME": name,
    "AMOUNT": amount,
    "PRICE": price,
    "COST": cost,
  };
}

/// Оплата в чеку
class CheckPayRow {
  final String payFormNm; // "ГОТІВКА" або "КАРТКА"
  final double sum;

  CheckPayRow({required this.payFormNm, required this.sum});

  Map<String, dynamic> toJson() => {"PAYFORMNM": payFormNm, "SUM": sum};
}

/// Підсумок чека
class CheckTotal {
  final double sum;

  CheckTotal({required this.sum});

  Map<String, dynamic> toJson() => {"SUM": sum};
}
