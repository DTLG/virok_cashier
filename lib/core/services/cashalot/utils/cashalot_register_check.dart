/// Головний об'єкт запиту RegisterCheck
class CashalotRegisterCheckRequest {
  final String command;
  final int numFiscal;
  final CashalotCheck check;
  final bool autoOpenShift;
  final bool getQrCode;
  final bool visualization;

  CashalotRegisterCheckRequest({
    required this.numFiscal,
    required this.check,
    this.command = 'RegisterCheck',
    this.autoOpenShift = true,
    this.getQrCode = true,
    this.visualization = true,
  });

  Map<String, dynamic> toJson() {
    return {
      "Command": command,
      "NumFiscal": numFiscal,
      "Check": check.toJson(),
      "AutoOpenShift": autoOpenShift,
      "GetQrCode": getQrCode,
      "Visualization": visualization,
    };
  }
}

/// Вкладений об'єкт "Check"
class CashalotCheck {
  final CashalotCheckHead head;
  final CashalotCheckTotal total;
  final List<CashalotCheckPay> pay;
  final List<CashalotCheckBody> body;
  // final List<CashalotCheckTax>? tax; // Розкоментуйте, якщо є податки

  CashalotCheck({
    required this.head,
    required this.total,
    required this.pay,
    required this.body,
  });

  Map<String, dynamic> toJson() {
    return {
      "CHECKHEAD": head.toJson(),
      "CHECKTOTAL": total.toJson(),
      "CHECKPAY": pay.map((e) => e.toJson()).toList(),
      "CHECKBODY": body.map((e) => e.toJson()).toList(),
      // "CHECKTAX": tax?.map((e) => e.toJson()).toList() ?? [],
    };
  }
}

class CashalotCheckHead {
  final String docType;
  final String docSubType;
  final String cashier;
  final String? comment;

  CashalotCheckHead({
    this.docType = "SaleGoods",
    this.docSubType = "CheckGoods",
    required this.cashier,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "DOCTYPE": docType,
      "DOCSUBTYPE": docSubType,
      "CASHIER": cashier,
    };
    if (comment != null) data["COMMENT"] = comment;
    return data;
  }
}

class CashalotCheckTotal {
  final double sum;
  final double? commission;

  CashalotCheckTotal({required this.sum, this.commission});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{"SUM": double.parse(sum.toStringAsFixed(2))};
    if (commission != null) {
      data["COMMISSION"] = double.parse(commission!.toStringAsFixed(2));
    }
    return data;
  }
}

class CashalotCheckPay {
  final String payFormNm; // "ГОТІВКА" або "КАРТКА"
  final double sum;
  final double? provided;
  final double? remains;

  CashalotCheckPay({
    required this.payFormNm,
    required this.sum,
    this.provided,
    this.remains,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      "PAYFORMNM": payFormNm,
      "SUM": double.parse(sum.toStringAsFixed(2)),
    };
    if (provided != null) data["PROVIDED"] = provided;
    if (remains != null) data["REMAINS"] = remains;
    return data;
  }
}

class CashalotCheckBody {
  final String code;
  final String name;
  final double amount;
  final double price;
  final String? uktzed;
  final String? barcode;

  CashalotCheckBody({
    required this.code,
    required this.name,
    required this.amount,
    required this.price,
    this.uktzed,
    this.barcode,
  });

  Map<String, dynamic> toJson() {
    // Важливо: COST має рахуватися як PRICE * AMOUNT з округленням
    final cost = double.parse((price * amount).toStringAsFixed(2));

    final data = <String, dynamic>{
      "CODE": code,
      "NAME": name,
      "AMOUNT": amount, // API приймає double (наприклад 1.000)
      "PRICE": double.parse(price.toStringAsFixed(2)),
      "COST": cost,
    };

    if (uktzed != null && uktzed!.isNotEmpty) data["UKTZED"] = uktzed;
    if (barcode != null && barcode!.isNotEmpty) data["BARCODE"] = barcode;

    return data;
  }
}
