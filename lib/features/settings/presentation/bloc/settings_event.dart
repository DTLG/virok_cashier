part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

final class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

final class UpdateThemeMode extends SettingsEvent {
  final ThemeMode themeMode;

  const UpdateThemeMode({required this.themeMode});

  @override
  List<Object> get props => [themeMode];
}

final class UpdateLanguage extends SettingsEvent {
  final String language;

  const UpdateLanguage({required this.language});

  @override
  List<Object> get props => [language];
}

final class ToggleNotifications extends SettingsEvent {
  final bool enabled;

  const ToggleNotifications(this.enabled);

  @override
  List<Object> get props => [enabled];
}

final class ToggleAutoSync extends SettingsEvent {
  final bool enabled;

  const ToggleAutoSync(this.enabled);

  @override
  List<Object> get props => [enabled];
}

final class UpdateSyncInterval extends SettingsEvent {
  final int minutes;

  const UpdateSyncInterval({required this.minutes});

  @override
  List<Object> get props => [minutes];
}

final class ToggleWifiOnlySync extends SettingsEvent {
  final bool enabled;

  const ToggleWifiOnlySync(this.enabled);

  @override
  List<Object> get props => [enabled];
}

final class SyncNow extends SettingsEvent {
  const SyncNow();
}

final class ToggleAutoPrintReceipts extends SettingsEvent {
  final bool enabled;

  const ToggleAutoPrintReceipts(this.enabled);

  @override
  List<Object> get props => [enabled];
}

final class UpdatePrinterName extends SettingsEvent {
  final String? printerName;

  const UpdatePrinterName({this.printerName});

  @override
  List<Object> get props => [printerName ?? ''];
}

final class UpdatePrinterIp extends SettingsEvent {
  final String? printerIp;

  const UpdatePrinterIp({this.printerIp});

  @override
  List<Object> get props => [printerIp ?? ''];
}

final class UpdatePrinterPort extends SettingsEvent {
  final int printerPort;

  const UpdatePrinterPort({required this.printerPort});

  @override
  List<Object> get props => [printerPort];
}

final class UpdateCurrency extends SettingsEvent {
  final String currency;

  const UpdateCurrency({required this.currency});

  @override
  List<Object> get props => [currency];
}

final class ToggleScreenLock extends SettingsEvent {
  final bool enabled;

  const ToggleScreenLock(this.enabled);

  @override
  List<Object> get props => [enabled];
}

final class UpdateScreenLockTimeout extends SettingsEvent {
  final int minutes;

  const UpdateScreenLockTimeout({required this.minutes});

  @override
  List<Object> get props => [minutes];
}

final class ClearCache extends SettingsEvent {
  const ClearCache();
}

final class Logout extends SettingsEvent {
  const Logout();
}
