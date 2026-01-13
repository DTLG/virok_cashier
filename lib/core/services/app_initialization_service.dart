import 'package:cash_register/core/widgets/notificarion_toast/view.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/nomenclatura/data/datasources/nomenclatura_remote_data_source.dart';
import '../../features/nomenclatura/data/datasources/nomenclatura_local_data_source.dart';
import '../../features/nomenclatura/data/repositories/nomenclatura_repository_impl.dart';
import '../../features/nomenclatura/domain/repositories/nomenclatura_repository.dart';
import '../../features/nomenclatura/domain/usecases/get_all_nomenclatura.dart';
import '../../features/nomenclatura/domain/usecases/search_nomenclatura.dart';
import '../../features/nomenclatura/domain/usecases/sync_nomenclatura.dart';
import '../../features/nomenclatura/domain/usecases/get_categories.dart';
import '../../features/nomenclatura/domain/usecases/get_subcategories.dart';
import 'data_sync_service.dart';
import 'storage_service.dart';
// import 'realtime_service.dart';
import '../widgets/sync_dialog.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../di/sync_injection.dart';
import '../di/home_injection.dart';
// import '../di/cashalot_injection.dart';
// import '../config/cashalot_config.dart';
import '../../services/vchasno_service.dart';

class AppInitializationService {
  static final GetIt _sl = GetIt.instance;
  static bool _isInitialized = false;

  /// Ініціалізує всі залежності додатку
  static Future<void> initializeDependencies() async {
    if (_isInitialized) return;

    try {
      // Реєстрація data sources
      _sl.registerLazySingleton<NomenclaturaRemoteDataSource>(
        () => NomenclaturaRemoteDataSourceImpl(
          supabaseClient: Supabase.instance.client,
        ),
      );

      _sl.registerLazySingleton<NomenclaturaLocalDataSource>(
        () => NomenclaturaLocalDataSourceImpl(),
      );

      // Реєстрація external залежностей
      _sl.registerLazySingleton(() => Connectivity());
      _sl.registerLazySingleton(() => StorageService());

      // Реєстрація repository
      _sl.registerLazySingleton<NomenclaturaRepository>(
        () => NomenclaturaRepositoryImpl(
          remoteDataSource: _sl<NomenclaturaRemoteDataSource>(),
          localDataSource: _sl<NomenclaturaLocalDataSource>(),
          connectivity: _sl<Connectivity>(),
        ),
      );

      // Реєстрація use cases
      _sl.registerLazySingleton(
        () => GetAllNomenclatura(_sl<NomenclaturaRepository>()),
      );
      _sl.registerLazySingleton(
        () => SearchNomenclatura(_sl<NomenclaturaRepository>()),
      );
      _sl.registerLazySingleton(
        () => SyncNomenclatura(_sl<NomenclaturaRepository>()),
      );
      _sl.registerLazySingleton(
        () => GetCategories(_sl<NomenclaturaRepository>()),
      );
      _sl.registerLazySingleton(
        () => GetSubcategories(_sl<NomenclaturaRepository>()),
      );

      // Реєстрація sync service
      // Реєструємо RealtimeService (відключено тимчасово)
      // _sl.registerLazySingleton<RealtimeService>(
      //   () => RealtimeService(Supabase.instance.client),
      // );

      _sl.registerLazySingleton<DataSyncService>(
        () => DataSyncServiceImpl(
          nomenclaturaRepository: _sl<NomenclaturaRepository>(),
          connectivity: _sl<Connectivity>(),
          // realtimeService: _sl<RealtimeService>(),
        ),
      );

      // Реєстрація SettingsBloc
      _sl.registerLazySingleton<SettingsBloc>(
        () => SettingsBloc(
          storageService: _sl<StorageService>(),
          dataSyncService: _sl<DataSyncService>(),
        ),
      );

      // Реєстрація Sync залежностей
      setupSyncInjection();

      // Реєстрація Home залежностей
      setupHomeInjection();

      // ❌ ВИДАЛЕНО: Реєстрація Cashalot залежностей
      // Старий код Cashalot закоментовано
      // final storageService = _sl<StorageService>();
      // final savedKeyPath = await storageService.getCashalotKeyPath();
      // final savedCertPath = await storageService.getCashalotCertPath();
      // final savedKeyPassword = await storageService.getCashalotKeyPassword();
      // final keyPath = savedKeyPath ?? CashalotConfig.keyPath;
      // final certPath = savedCertPath ?? CashalotConfig.certPath;
      // final keyPassword = savedKeyPassword ?? CashalotConfig.keyPassword;
      // setupCashalotInjection(
      //   useReal: CashalotConfig.useReal,
      //   baseUrl: CashalotConfig.baseUrl,
      //   keyPath: keyPath,
      //   certPath: certPath,
      //   keyPassword: keyPassword,
      //   defaultPrroFiscalNum: CashalotConfig.defaultPrroFiscalNum,
      // );

      // ✅ ДОДАНО: Реєстрація VchasnoService
      _sl.registerLazySingleton<VchasnoService>(() => VchasnoService());

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize dependencies: $e');
    }
  }

  /// Результат ініціалізації програми
  static Future<AppInitResult> checkDataAndInitialize() async {
    try {
      if (!_isInitialized) {
        await initializeDependencies();
      }

      final syncService = _sl<DataSyncService>();
      final syncInfo = await syncService.checkSyncStatus();

      // Якщо дані актуальні, переходимо на головну сторінку
      if (syncInfo.status == SyncStatus.upToDate) {
        return AppInitResult.goToHome();
      }

      // Якщо дані неактуальні або відсутні, переходимо до синхронізації
      if (syncInfo.needsSync || syncInfo.status == SyncStatus.noConnection) {
        return AppInitResult.goToSync();
      }

      // В інших випадках переходимо на головну сторінку
      return AppInitResult.goToHome();
    } catch (e) {
      // При помилці переходимо до синхронізації для налаштування
      return AppInitResult.goToSync(errorMessage: 'Помилка ініціалізації: $e');
    }
  }

  /// Перевіряє статус даних і показує діалог синхронізації при необхідності
  static Future<bool> checkDataAndSync(BuildContext context) async {
    try {
      if (!_isInitialized) {
        await initializeDependencies();
      }

      final syncService = _sl<DataSyncService>();
      final syncInfo = await syncService.checkSyncStatus();

      // Якщо дані актуальні, продовжуємо роботу
      if (syncInfo.status == SyncStatus.upToDate) {
        return true;
      }

      // Якщо дані неактуальні або відсутні, показуємо діалог
      if (syncInfo.needsSync || syncInfo.status == SyncStatus.noConnection) {
        final shouldContinue = await showSyncDialog(
          context: context,
          syncInfo: syncInfo,
          syncService: syncService,
        );

        // Якщо користувач закрив діалог або вибрав "Пропустити"
        return shouldContinue ?? false;
      }

      // В інших випадках (помилки) продовжуємо роботу
      return true;
    } catch (e) {
      // При помилці показуємо повідомлення і продовжуємо роботу
      if (context.mounted) {
        ToastManager.show(
          context,
          type: ToastType.error,
          title: 'Помилка ініціалізації: $e',
        );
      }
      return true;
    }
  }

  /// Очищає всі зареєстровані залежності
  static Future<void> reset() async {
    await _sl.reset();
    _isInitialized = false;
  }

  /// Перевіряє чи ініціалізовані залежності
  static bool get isInitialized => _isInitialized;

  /// Отримує зареєстровану залежність
  static T get<T extends Object>() => _sl<T>();
}

/// Результат ініціалізації програми
class AppInitResult {
  final AppInitDestination destination;
  final String? errorMessage;

  const AppInitResult._({required this.destination, this.errorMessage});

  factory AppInitResult.goToHome() =>
      const AppInitResult._(destination: AppInitDestination.home);

  factory AppInitResult.goToSync({String? errorMessage}) => AppInitResult._(
    destination: AppInitDestination.sync,
    errorMessage: errorMessage,
  );
}

/// Можливі призначення після ініціалізації
enum AppInitDestination { home, sync }
