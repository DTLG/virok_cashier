/// Інформація про ПРРО (касу)
class PrroInfo {
  final String numFiscal; // Фіскальний номер
  final String name; // Назва каси
  final String? address; // Адреса (якщо є)
  final String? serialNumber; // Серійний номер (якщо є)

  PrroInfo({
    required this.numFiscal,
    required this.name,
    this.address,
    this.serialNumber,
  });

  /// Створює PrroInfo з даних API
  factory PrroInfo.fromJson(Map<String, dynamic> json) {
    return PrroInfo(
      numFiscal: json['NumFiscal']?.toString() ?? '',
      name: json['Name'] as String? ?? 'Без назви',
      address: json['Address'] as String?,
      serialNumber: json['SerialNumber'] as String?,
    );
  }

  /// Конвертує в JSON
  Map<String, dynamic> toJson() => {
        'NumFiscal': numFiscal,
        'Name': name,
        if (address != null) 'Address': address,
        if (serialNumber != null) 'SerialNumber': serialNumber,
      };

  @override
  String toString() => '$name ($numFiscal)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrroInfo &&
          runtimeType == other.runtimeType &&
          numFiscal == other.numFiscal;

  @override
  int get hashCode => numFiscal.hashCode;
}




