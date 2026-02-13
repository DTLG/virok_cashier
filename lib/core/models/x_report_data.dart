/// Дані звіту (X або Z)
class XReportData {
  /// Тип завдання (10 = X-звіт, 11 = Z-звіт)
  final int task;
  final String? dt; // Дата та час
  final String? fisid; // Фіскальний номер ПРРО
  final String? cashier; // Касир
  final double safe; // Поточний залишок готівки
  final double safeStartShift; // Залишок на початок зміни
  final bool isOffline; // Офлайн режим
  final int? shiftLink; // Поточний номер Z-звіту
  final int? shiftPrevLink; // Номер попереднього Z-звіту
  final int? vacantOffNums; // Кількість доступних офлайн номерів
  final String? visualization; // Base64 рядкова візуалізація
  final bool isZRep; // Чи є Z-звіт

  final DateTime? shiftOpened; // Час відкриття зміни
  final double? serviceInput; // Службове внесення
  final double? serviceOutput; // Службова видача

  // Підсумки по чеках
  final ReceiptSummary? receipt;

  // Загальні підсумки
  final SummaryData? summary;

  // Податки
  final List<TaxData> taxes;

  // Оплати
  final List<PayData> pays;

  // Операції з грошима
  final List<MoneyData> money;

  // Видача коштів
  final List<CashData> cash;

  // Останній чек
  final LastCheckData? lastCheck;

  // Попередження
  final List<WarningData> warnings;

  // Інформація про тариф
  final BillingData? billing;

  // Інформація для друку
  final PrintHeaderData? printHeader;

  XReportData({
    this.task = 0,
    this.dt,
    this.fisid,
    this.cashier,
    this.safe = 0.0,
    this.safeStartShift = 0.0,
    this.isOffline = false,
    this.shiftLink,
    this.shiftPrevLink,
    this.vacantOffNums,
    this.receipt,
    this.summary,
    this.taxes = const [],
    this.pays = const [],
    this.money = const [],
    this.cash = const [],
    this.lastCheck,
    this.warnings = const [],
    this.billing,
    this.printHeader,
    this.visualization,
    this.isZRep = false,
    this.shiftOpened,
    this.serviceInput,
    this.serviceOutput,
  });

  factory XReportData.fromJson(Map<String, dynamic> json) {
    // Спроба знайти info (для сумісності зі старою логікою)
    final info = json['info'] as Map<String, dynamic>? ?? json;

    // --- ЛОГІКА ПАРСИНГУ НОВИХ ПОЛІВ ---

    // 1. ShiftOpened (Зазвичай лежить в корені JSON від Cashalot)
    DateTime? parsedShiftOpened;
    if (json['ShiftOpened'] != null) {
      try {
        parsedShiftOpened = DateTime.parse(json['ShiftOpened'].toString());
      } catch (e) {
        // debugPrint('Error parsing ShiftOpened: $e');
      }
    }

    // 2. Службові операції (Вкладені в Totals -> ZREPBODY)
    double? parsedServiceInput;
    double? parsedServiceOutput;

    if (json['Totals'] != null && json['Totals'] is Map) {
      final totalsBody = json['Totals']['ZREPBODY'];
      if (totalsBody != null && totalsBody is Map) {
        parsedServiceInput = double.tryParse(
          totalsBody['SERVICEINPUT']?.toString() ?? '',
        );
        parsedServiceOutput = double.tryParse(
          totalsBody['SERVICEOUTPUT']?.toString() ?? '',
        );
      }
    }

    return XReportData(
      // Заповнюємо нові поля
      shiftOpened: parsedShiftOpened,
      serviceInput: parsedServiceInput,
      serviceOutput: parsedServiceOutput,

      // ... Ваші старі поля (без змін) ...
      task: (info['task'] is int) ? info['task'] : 0,
      dt:
          info['dt'] as String? ??
          json['OrderDateTime'] as String?, // Додав фолбек
      fisid: info['fisid'] as String? ?? json['NumFiscal'] as String?,
      cashier: info['cashier'] as String?,
      visualization: json['Visualization'] as String?, // Беремо з кореня
      // ... Решта полів ...
      safe: (info['safe'] as num?)?.toDouble() ?? 0.0,
      safeStartShift: (info['safe_start_shift'] as num?)?.toDouble() ?? 0.0,
      isOffline:
          info['isoffline'] as bool? ?? json['Offline'] as bool? ?? false,
      shiftLink: info['shift_link'] as int?,

      receipt: info['receipt'] != null
          ? ReceiptSummary.fromJson(info['receipt'] as Map<String, dynamic>)
          : null,
      summary: info['summary'] != null
          ? SummaryData.fromJson(info['summary'] as Map<String, dynamic>)
          : null,
      taxes:
          (info['taxes'] as List?)
              ?.map((e) => TaxData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pays:
          (info['pays'] as List?)
              ?.map((e) => PayData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      warnings:
          (json['warnings'] as List?)
              ?.map((e) => WarningData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ReceiptSummary {
  final int lastDocnoP; // Останній номер чеку на продаж
  final int lastDocnoM; // Останній номер чеку повернення
  final int count14; // Кількість чеків видачі готівки
  final int countP; // Кількість чеків на продаж
  final int countM; // Кількість чеків повернення

  ReceiptSummary({
    required this.lastDocnoP,
    required this.lastDocnoM,
    required this.count14,
    required this.countP,
    required this.countM,
  });

  factory ReceiptSummary.fromJson(Map<String, dynamic> json) {
    return ReceiptSummary(
      lastDocnoP: json['last_docno_p'] as int? ?? 0,
      lastDocnoM: json['last_docno_m'] as int? ?? 0,
      count14: json['count_14'] as int? ?? 0,
      countP: json['count_p'] as int? ?? 0,
      countM: json['count_m'] as int? ?? 0,
    );
  }
}

class SummaryData {
  final double baseP; // Оборот продажу
  final double baseM; // Оборот повернення
  final double taxexP; // Додаткові збори продажу
  final double taxexM; // Додаткові збори повернення
  final double discP; // Знижка продажу
  final double discM; // Знижка повернення
  final double calcP; // Оборот продажу з округленням
  final double calcM; // Оборот повернення з округленням

  SummaryData({
    required this.baseP,
    required this.baseM,
    required this.taxexP,
    required this.taxexM,
    required this.discP,
    required this.discM,
    required this.calcP,
    required this.calcM,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      baseP: (json['base_p'] as num?)?.toDouble() ?? 0.0,
      baseM: (json['base_m'] as num?)?.toDouble() ?? 0.0,
      taxexP: (json['taxex_p'] as num?)?.toDouble() ?? 0.0,
      taxexM: (json['taxex_m'] as num?)?.toDouble() ?? 0.0,
      discP: (json['disc_p'] as num?)?.toDouble() ?? 0.0,
      discM: (json['disc_m'] as num?)?.toDouble() ?? 0.0,
      calcP: (json['calc_p'] as num?)?.toDouble() ?? 0.0,
      calcM: (json['calc_m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TaxData {
  final int grCode;
  final double baseSumP;
  final double baseSumM;
  final String taxName;
  final String taxFname;
  final String taxLit;
  final double taxPercent;
  final double taxSumP;
  final double taxSumM;

  TaxData({
    required this.grCode,
    required this.baseSumP,
    required this.baseSumM,
    required this.taxName,
    required this.taxFname,
    required this.taxLit,
    required this.taxPercent,
    required this.taxSumP,
    required this.taxSumM,
  });

  factory TaxData.fromJson(Map<String, dynamic> json) {
    return TaxData(
      grCode: json['gr_code'] as int? ?? 0,
      baseSumP: (json['base_sum_p'] as num?)?.toDouble() ?? 0.0,
      baseSumM: (json['base_sum_m'] as num?)?.toDouble() ?? 0.0,
      taxName: json['tax_name'] as String? ?? '',
      taxFname: json['tax_fname'] as String? ?? '',
      taxLit: json['tax_lit'] as String? ?? '',
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxSumP: (json['tax_sum_p'] as num?)?.toDouble() ?? 0.0,
      taxSumM: (json['tax_sum_m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PayData {
  final int type;
  final String name;
  final double sumP;
  final double sumM;

  PayData({
    required this.type,
    required this.name,
    required this.sumP,
    required this.sumM,
  });

  factory PayData.fromJson(Map<String, dynamic> json) {
    return PayData(
      type: json['type'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sumP: (json['sum_p'] as num?)?.toDouble() ?? 0.0,
      sumM: (json['sum_m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MoneyData {
  final int type;
  final String name;
  final double sumP;
  final double sumM;

  MoneyData({
    required this.type,
    required this.name,
    required this.sumP,
    required this.sumM,
  });

  factory MoneyData.fromJson(Map<String, dynamic> json) {
    return MoneyData(
      type: json['type'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sumP: (json['sum_p'] as num?)?.toDouble() ?? 0.0,
      sumM: (json['sum_m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CashData {
  final int type;
  final String name;
  final double sumM;

  CashData({required this.type, required this.name, required this.sumM});

  factory CashData.fromJson(Map<String, dynamic> json) {
    return CashData(
      type: json['type'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sumM: (json['sum_m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class LastCheckData {
  final int packnum;
  final int docnum;
  final String fisnum;
  final int packtype;

  LastCheckData({
    required this.packnum,
    required this.docnum,
    required this.fisnum,
    required this.packtype,
  });

  factory LastCheckData.fromJson(Map<String, dynamic> json) {
    return LastCheckData(
      packnum: json['packnum'] as int? ?? 0,
      docnum: json['docnum'] as int? ?? 0,
      fisnum: json['fisnum'] as String? ?? '',
      packtype: json['packtype'] as int? ?? 0,
    );
  }
}

class WarningData {
  final int code;
  final String wtxt;

  WarningData({required this.code, required this.wtxt});

  factory WarningData.fromJson(Map<String, dynamic> json) {
    return WarningData(
      code: json['code'] as int? ?? 0,
      wtxt: json['wtxt'] as String? ?? '',
    );
  }
}

class BillingData {
  final String paidDateTo;
  final int enoughToRenewSubscription;

  BillingData({
    required this.paidDateTo,
    required this.enoughToRenewSubscription,
  });

  factory BillingData.fromJson(Map<String, dynamic> json) {
    return BillingData(
      paidDateTo: json['paid_date_to'] as String? ?? '',
      enoughToRenewSubscription:
          json['enough_to_renew_subscription'] as int? ?? 0,
    );
  }
}

class PrintHeaderData {
  final String? name;
  final String? shopname;
  final String? shopad;
  final String? vatCode;
  final String? fisCode;
  final String? dt;
  final bool isOffline;
  final String? fisid;
  final String? cashier;

  PrintHeaderData({
    this.name,
    this.shopname,
    this.shopad,
    this.vatCode,
    this.fisCode,
    this.dt,
    this.isOffline = false,
    this.fisid,
    this.cashier,
  });

  factory PrintHeaderData.fromJson(Map<String, dynamic> json) {
    return PrintHeaderData(
      name: json['name'] as String?,
      shopname: json['shopname']?.toString(),
      shopad: json['shopad'] as String?,
      vatCode: json['vat_code'] as String?,
      fisCode: json['fis_code'] as String?,
      dt: json['dt'] as String?,
      isOffline: json['isOffline'] as bool? ?? false,
      fisid: json['fisid'] as String?,
      cashier: json['cashier'] as String?,
    );
  }
}
