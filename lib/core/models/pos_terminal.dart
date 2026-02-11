class PosTerminal {
  final String id;
  final String ipAddress;
  final String port;
  final String driverPath;
  final String merchantName;
  final String merchantId;
  final String comPort;
  final bool isDefault; // DefaultDevice
  final String name; // NameTerminal

  PosTerminal({
    required this.id,
    required this.ipAddress,
    required this.port,
    required this.driverPath,
    required this.merchantName,
    required this.merchantId,
    required this.comPort,
    required this.isDefault,
    required this.name,
  });

  factory PosTerminal.fromJson(Map<String, dynamic> json) {
    return PosTerminal(
      id: json['ID']?.toString() ?? '',
      ipAddress: json['IPAddress']?.toString() ?? '',
      port: json['Port']?.toString() ?? '',
      driverPath: json['DriverPath']?.toString() ?? '',
      merchantName: json['MerchantName']?.toString() ?? '',
      merchantId: json['MerchantID']?.toString() ?? '',
      comPort: json['ComPort']?.toString() ?? '',
      isDefault:
          json['DefaultDevice'] == true || json['DefaultDevice'] == 'true',
      name: json['NameTerminal']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'PosTerminal(name: $name, ip: $ipAddress:$port, default: $isDefault)';
}
