import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/data_sync_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final StorageService storageService;
  final DataSyncService? dataSyncService;

  SettingsBloc({required this.storageService, this.dataSyncService})
    : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateLanguage>(_onUpdateLanguage);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ToggleAutoSync>(_onToggleAutoSync);
    on<UpdateSyncInterval>(_onUpdateSyncInterval);
    on<ToggleWifiOnlySync>(_onToggleWifiOnlySync);
    on<SyncNow>(_onSyncNow);
    on<ToggleAutoPrintReceipts>(_onToggleAutoPrintReceipts);
    on<UpdatePrinterName>(_onUpdatePrinterName);
    on<UpdatePrinterIp>(_onUpdatePrinterIp);
    on<UpdatePrinterPort>(_onUpdatePrinterPort);
    on<UpdateCurrency>(_onUpdateCurrency);
    on<ToggleScreenLock>(_onToggleScreenLock);
    on<UpdateScreenLockTimeout>(_onUpdateScreenLockTimeout);
    on<ClearCache>(_onClearCache);
    on<Logout>(_onLogout);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Завантажуємо налаштування з SharedPreferences
      final themeModeString =
          await storageService.getString('theme_mode') ?? 'system';
      final themeMode = _parseThemeMode(themeModeString);

      final language = await storageService.getString('language') ?? 'uk';
      final notificationsEnabled =
          await storageService.getBool('notifications_enabled') ?? true;
      final autoSyncEnabled =
          await storageService.getBool('auto_sync_enabled') ?? true;
      final syncIntervalMinutes =
          await storageService.getInt('sync_interval_minutes') ?? 30;
      final wifiOnlySync =
          await storageService.getBool('wifi_only_sync') ?? false;
      final autoPrintReceipts =
          await storageService.getBool('auto_print_receipts') ?? false;
      final printerName = await storageService.getString('printer_name');
      final printerIp = await storageService.getString('printer_ip');
      final printerPort = await storageService.getInt('printer_port') ?? 9100;
      final currency = await storageService.getString('currency') ?? 'UAH';
      final screenLockEnabled =
          await storageService.getBool('screen_lock_enabled') ?? false;
      final screenLockTimeoutMinutes =
          await storageService.getInt('screen_lock_timeout_minutes') ?? 5;

      // Отримуємо версію додатку
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';

      // Отримуємо час останньої синхронізації
      final lastSyncTime = await storageService.getDateTime('last_sync_time');

      emit(
        state.copyWith(
          themeMode: themeMode,
          language: language,
          notificationsEnabled: notificationsEnabled,
          autoSyncEnabled: autoSyncEnabled,
          syncIntervalMinutes: syncIntervalMinutes,
          wifiOnlySync: wifiOnlySync,
          autoPrintReceipts: autoPrintReceipts,
          printerName: printerName,
          printerIp: printerIp,
          printerPort: printerPort,
          currency: currency,
          screenLockEnabled: screenLockEnabled,
          screenLockTimeoutMinutes: screenLockTimeoutMinutes,
          appVersion: appVersion,
          lastSyncTime: lastSyncTime,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Помилка завантаження налаштувань: $e',
        ),
      );
    }
  }

  void _onUpdateThemeMode(UpdateThemeMode event, Emitter<SettingsState> emit) {
    storageService.setString('theme_mode', event.themeMode.name);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onUpdateLanguage(UpdateLanguage event, Emitter<SettingsState> emit) {
    storageService.setString('language', event.language);
    emit(state.copyWith(language: event.language));
  }

  void _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) {
    storageService.setBool('notifications_enabled', event.enabled);
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }

  void _onToggleAutoSync(ToggleAutoSync event, Emitter<SettingsState> emit) {
    storageService.setBool('auto_sync_enabled', event.enabled);
    emit(state.copyWith(autoSyncEnabled: event.enabled));
  }

  void _onUpdateSyncInterval(
    UpdateSyncInterval event,
    Emitter<SettingsState> emit,
  ) {
    storageService.setInt('sync_interval_minutes', event.minutes);
    emit(state.copyWith(syncIntervalMinutes: event.minutes));
  }

  void _onToggleWifiOnlySync(
    ToggleWifiOnlySync event,
    Emitter<SettingsState> emit,
  ) {
    storageService.setBool('wifi_only_sync', event.enabled);
    emit(state.copyWith(wifiOnlySync: event.enabled));
  }

  Future<void> _onSyncNow(SyncNow event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Виконуємо синхронізацію
      if (dataSyncService != null) {
        await dataSyncService!.syncAllData();
      }

      // Оновлюємо час останньої синхронізації
      final now = DateTime.now();
      await storageService.setDateTime('last_sync_time', now);

      emit(state.copyWith(lastSyncTime: now, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Помилка синхронізації: $e',
        ),
      );
    }
  }

  void _onToggleAutoPrintReceipts(
    ToggleAutoPrintReceipts event,
    Emitter<SettingsState> emit,
  ) {
    storageService.setBool('auto_print_receipts', event.enabled);
    emit(state.copyWith(autoPrintReceipts: event.enabled));
  }

  void _onUpdatePrinterName(
    UpdatePrinterName event,
    Emitter<SettingsState> emit,
  ) {
    if (event.printerName != null) {
      storageService.setString('printer_name', event.printerName!);
    } else {
      storageService.remove('printer_name');
    }
    emit(state.copyWith(printerName: event.printerName));
  }

  void _onUpdatePrinterIp(
    UpdatePrinterIp event,
    Emitter<SettingsState> emit,
  ) {
    if (event.printerIp != null && event.printerIp!.isNotEmpty) {
      storageService.setString('printer_ip', event.printerIp!);
    } else {
      storageService.remove('printer_ip');
    }
    emit(state.copyWith(printerIp: event.printerIp));
  }

  void _onUpdatePrinterPort(
    UpdatePrinterPort event,
    Emitter<SettingsState> emit,
  ) {
    storageService.setInt('printer_port', event.printerPort);
    emit(state.copyWith(printerPort: event.printerPort));
  }

  void _onUpdateCurrency(UpdateCurrency event, Emitter<SettingsState> emit) {
    storageService.setString('currency', event.currency);
    emit(state.copyWith(currency: event.currency));
  }

  void _onToggleScreenLock(
    ToggleScreenLock event,
    Emitter<SettingsState> emit,
  ) {
    storageService.setBool('screen_lock_enabled', event.enabled);
    emit(state.copyWith(screenLockEnabled: event.enabled));
  }

  void _onUpdateScreenLockTimeout(
    UpdateScreenLockTimeout event,
    Emitter<SettingsState> emit,
  ) {
    storageService.setInt('screen_lock_timeout_minutes', event.minutes);
    emit(state.copyWith(screenLockTimeoutMinutes: event.minutes));
  }

  Future<void> _onClearCache(
    ClearCache event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Очищаємо кеш
      if (dataSyncService != null) {
        await dataSyncService!.clearCache();
      }

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Помилка очищення кешу: $e',
        ),
      );
    }
  }

  Future<void> _onLogout(Logout event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Очищаємо дані користувача
      await storageService.clearUserData();

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Помилка виходу: $e'),
      );
    }
  }

  ThemeMode _parseThemeMode(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
