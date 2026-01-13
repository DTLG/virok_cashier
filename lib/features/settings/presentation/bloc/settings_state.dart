part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final String language;
  final bool notificationsEnabled;
  final bool autoSyncEnabled;
  final int syncIntervalMinutes;
  final bool wifiOnlySync;
  final DateTime? lastSyncTime;
  final bool autoPrintReceipts;
  final String? printerName;
  final String? printerIp;
  final int printerPort;
  final String currency;
  final bool screenLockEnabled;
  final int screenLockTimeoutMinutes;
  final String appVersion;
  final bool isLoading;
  final String? errorMessage;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.language = 'uk',
    this.notificationsEnabled = true,
    this.autoSyncEnabled = true,
    this.syncIntervalMinutes = 30,
    this.wifiOnlySync = false,
    this.lastSyncTime,
    this.autoPrintReceipts = false,
    this.printerName,
    this.printerIp,
    this.printerPort = 9100,
    this.currency = 'UAH',
    this.screenLockEnabled = false,
    this.screenLockTimeoutMinutes = 5,
    this.appVersion = '1.0.0',
    this.isLoading = false,
    this.errorMessage,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? language,
    bool? notificationsEnabled,
    bool? autoSyncEnabled,
    int? syncIntervalMinutes,
    bool? wifiOnlySync,
    DateTime? lastSyncTime,
    bool? autoPrintReceipts,
    String? printerName,
    String? printerIp,
    int? printerPort,
    String? currency,
    bool? screenLockEnabled,
    int? screenLockTimeoutMinutes,
    String? appVersion,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      wifiOnlySync: wifiOnlySync ?? this.wifiOnlySync,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      autoPrintReceipts: autoPrintReceipts ?? this.autoPrintReceipts,
      printerName: printerName ?? this.printerName,
      printerIp: printerIp ?? this.printerIp,
      printerPort: printerPort ?? this.printerPort,
      currency: currency ?? this.currency,
      screenLockEnabled: screenLockEnabled ?? this.screenLockEnabled,
      screenLockTimeoutMinutes:
          screenLockTimeoutMinutes ?? this.screenLockTimeoutMinutes,
      appVersion: appVersion ?? this.appVersion,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    language,
    notificationsEnabled,
    autoSyncEnabled,
    syncIntervalMinutes,
    wifiOnlySync,
    lastSyncTime,
    autoPrintReceipts,
    printerName,
    printerIp,
    printerPort,
    currency,
    screenLockEnabled,
    screenLockTimeoutMinutes,
    appVersion,
    isLoading,
    errorMessage,
  ];
}
