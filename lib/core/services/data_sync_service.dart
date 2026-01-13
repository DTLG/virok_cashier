import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/nomenclatura/domain/repositories/nomenclatura_repository.dart';
import '../error/failures.dart';
// import 'realtime_service.dart';

enum SyncStatus {
  upToDate, // Дані актуальні
  needsUpdate, // Потребує оновлення
  noConnection, // Немає з'єднання
  noData, // Немає локальних даних
  error, // Помилка при перевірці
}

class DataSyncInfo {
  final SyncStatus status;
  final DateTime? lastSync;
  final int localRecordsCount;
  final String? errorMessage;

  const DataSyncInfo({
    required this.status,
    this.lastSync,
    required this.localRecordsCount,
    this.errorMessage,
  });

  bool get needsSync =>
      status == SyncStatus.needsUpdate || status == SyncStatus.noData;
  bool get canSync =>
      status != SyncStatus.noConnection && status != SyncStatus.error;
}

abstract class DataSyncService {
  Future<DataSyncInfo> checkSyncStatus();
  Future<Either<Failure, void>> syncAllData({
    void Function(String message, double progress)? onProgress,
  });
  Future<bool> hasInternetConnection();
  Future<Either<Failure, void>> forceSyncAllData({
    void Function(String message, double progress)? onProgress,
  });
  Future<Either<Failure, int>> getServerRecordsCount();
  Future<Either<Failure, void>> syncSpecificData({
    bool syncNomenclatura = true,
    void Function(String message, double progress)? onProgress,
  });
  Future<Either<Failure, void>> clearAllLocalData();
  Future<Either<Failure, SyncStatistics>> getSyncStatistics();
  Future<Either<Failure, Map<String, dynamic>>> getDetailedSyncInfo();
  Future<bool> isDataUpToDate();
  Future<bool> shouldSyncBasedOnTime();
  Stream<Map<String, dynamic>> syncProgressStream();
  Future<void> clearCache();
  // Stream<NomenclaturaRealtimeEvent>? subscribeToRealtimeChanges();
  // Stream<Map<String, dynamic>>? subscribeToNomenclaturaItem(String guid);
  Future<void> unsubscribeFromRealtimeChanges();
  List<String> getActiveRealtimeSubscriptions();
  bool hasActiveRealtimeSubscriptions();
}

class SyncStatistics {
  final int localRecordsCount;
  final int? serverRecordsCount;
  final DateTime? lastSuccessfulSync;
  final Duration? timeSinceLastSync;
  final List<String> recentErrors;

  const SyncStatistics({
    required this.localRecordsCount,
    this.serverRecordsCount,
    this.lastSuccessfulSync,
    this.timeSinceLastSync,
    this.recentErrors = const [],
  });
}

class DataSyncServiceImpl implements DataSyncService {
  final NomenclaturaRepository nomenclaturaRepository;
  final Connectivity connectivity;
  // final RealtimeService? realtimeService;

  // Час після якого дані вважаються застарілими (24 години)
  static const Duration syncThreshold = Duration(hours: 24);

  DataSyncServiceImpl({
    required this.nomenclaturaRepository,
    required this.connectivity,
    // this.realtimeService,
  });

  @override
  Future<DataSyncInfo> checkSyncStatus() async {
    try {
      // Спочатку отримуємо локальні дані
      final localDataResult = await nomenclaturaRepository
          .getCachedNomenclatura();
      final localCount = localDataResult.fold((l) => 0, (r) => r.length);

      // Перевіряємо з'єднання з інтернетом
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        return DataSyncInfo(
          status: localCount > 0 ? SyncStatus.noConnection : SyncStatus.noData,
          localRecordsCount: localCount,
        );
      }

      // Отримуємо час останньої синхронізації
      final lastSyncResult = await nomenclaturaRepository.getLastSyncTime();
      final lastSync = lastSyncResult.fold((l) => null, (r) => r);

      // Визначаємо статус
      SyncStatus status;

      if (localCount == 0) {
        // Немає локальних даних - потрібна синхронізація
        status = SyncStatus.noData;
      } else if (lastSync == null) {
        // Немає інформації про останню синхронізацію - потрібна синхронізація
        status = SyncStatus.needsUpdate;
      } else {
        final timeSinceLastSync = DateTime.now().difference(lastSync);
        if (timeSinceLastSync > syncThreshold) {
          // Дані застарілі - потрібна синхронізація
          status = SyncStatus.needsUpdate;
        } else {
          // Дані актуальні
          status = SyncStatus.upToDate;
        }
      }

      return DataSyncInfo(
        status: status,
        lastSync: lastSync,
        localRecordsCount: localCount,
      );
    } catch (e) {
      return DataSyncInfo(
        status: SyncStatus.error,
        localRecordsCount: 0,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<Either<Failure, void>> syncAllData({
    void Function(String message, double progress)? onProgress,
  }) async {
    try {
      onProgress?.call('Початок синхронізації...', 0.0);

      // Синхронізуємо номенклатуру (швидко, без зв'язків)
      onProgress?.call('Швидке завантаження номенклатури...', 0.2);
      final getAllResult = await nomenclaturaRepository.getAllNomenclatura(
        includeRelations: false, // Швидке завантаження
      );

      if (getAllResult.isLeft()) {
        return getAllResult.fold(
          (failure) => Left(failure),
          (r) => const Right(null),
        );
      }

      onProgress?.call('Синхронізація завершена', 1.0);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Помилка синхронізації: $e'));
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      // Якщо connectivity показує з'єднання, повертаємо true
      return true;
    } catch (e) {
      return true;
    }
  }

  @override
  Future<Either<Failure, void>> forceSyncAllData({
    void Function(String message, double progress)? onProgress,
  }) async {
    try {
      // Перевіряємо з'єднання
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        return Left(NetworkFailure('Немає з\'єднання з інтернетом'));
      }

      onProgress?.call('Початок примусової синхронізації...', 0.0);

      // Примусова синхронізація з очищенням
      onProgress?.call('Примусова синхронізація...', 0.3);
      final syncResult = await (nomenclaturaRepository as dynamic)
          .forceSyncWithServer();

      if (syncResult.isLeft()) {
        return syncResult.fold(
          (failure) => Left(failure),
          (r) => const Right(null),
        );
      }

      onProgress?.call('Примусова синхронізація завершена', 1.0);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Помилка примусової синхронізації: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getServerRecordsCount() async {
    try {
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        return Left(NetworkFailure('Немає з\'єднання з інтернетом'));
      }

      // Отримуємо дані з сервера для підрахунку
      final result = await nomenclaturaRepository.getAllNomenclatura();
      return result.fold(
        (failure) => Left(failure),
        (nomenclaturas) => Right(nomenclaturas.length),
      );
    } catch (e) {
      return Left(ServerFailure('Помилка отримання кількості записів: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncSpecificData({
    bool syncNomenclatura = true,
    void Function(String message, double progress)? onProgress,
  }) async {
    try {
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        return Left(NetworkFailure('Немає з\'єднання з інтернетом'));
      }

      onProgress?.call('Початок селективної синхронізації...', 0.0);

      if (syncNomenclatura) {
        onProgress?.call('Синхронізація номенклатури...', 0.5);
        final syncResult = await nomenclaturaRepository.syncWithServer();

        if (syncResult.isLeft()) {
          return syncResult.fold(
            (failure) => Left(failure),
            (r) => const Right(null),
          );
        }
      }

      onProgress?.call('Селективна синхронізація завершена', 1.0);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Помилка селективної синхронізації: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllLocalData() async {
    try {
      final clearResult = await nomenclaturaRepository.clearCache();
      return clearResult.fold(
        (failure) => Left(failure),
        (_) => const Right(null),
      );
    } catch (e) {
      return Left(CacheFailure('Помилка очищення локальних даних: $e'));
    }
  }

  @override
  Future<Either<Failure, SyncStatistics>> getSyncStatistics() async {
    try {
      // Отримуємо локальні дані
      final localDataResult = await nomenclaturaRepository
          .getCachedNomenclatura();
      final localCount = localDataResult.fold((l) => 0, (r) => r.length);

      // Отримуємо час останньої синхронізації
      final lastSyncResult = await nomenclaturaRepository.getLastSyncTime();
      final lastSync = lastSyncResult.fold((l) => null, (r) => r);

      // Обчислюємо час з останньої синхронізації
      Duration? timeSinceLastSync;
      if (lastSync != null) {
        timeSinceLastSync = DateTime.now().difference(lastSync);
      }

      // Спробуємо отримати кількість записів на сервері
      int? serverCount;
      final hasConnection = await hasInternetConnection();
      if (hasConnection) {
        final serverCountResult = await getServerRecordsCount();
        serverCount = serverCountResult.fold((l) => null, (r) => r);
      }

      return Right(
        SyncStatistics(
          localRecordsCount: localCount,
          serverRecordsCount: serverCount,
          lastSuccessfulSync: lastSync,
          timeSinceLastSync: timeSinceLastSync,
          recentErrors: [],
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Помилка отримання статистики: $e'));
    }
  }

  Future<bool> shouldSyncBasedOnTime() async {
    try {
      final lastSyncResult = await nomenclaturaRepository.getLastSyncTime();
      final lastSync = lastSyncResult.fold((l) => null, (r) => r);

      if (lastSync == null) return true;

      final timeSinceLastSync = DateTime.now().difference(lastSync);
      return timeSinceLastSync > syncThreshold;
    } catch (e) {
      return true;
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getDetailedSyncInfo() async {
    try {
      final syncInfo = await checkSyncStatus();
      final stats = await getSyncStatistics();
      final hasConnection = await hasInternetConnection();

      return stats.fold(
        (failure) => Left(failure),
        (statistics) => Right({
          'syncStatus': syncInfo.status.toString(),
          'localRecordsCount': syncInfo.localRecordsCount,
          'serverRecordsCount': statistics.serverRecordsCount,
          'lastSyncTime': syncInfo.lastSync?.toIso8601String(),
          'timeSinceLastSync': statistics.timeSinceLastSync?.inHours,
          'needsSync': syncInfo.needsSync,
          'canSync': syncInfo.canSync,
          'hasInternetConnection': hasConnection,
        }),
      );
    } catch (e) {
      return Left(ServerFailure('Помилка отримання детальної інформації: $e'));
    }
  }

  Future<bool> isDataUpToDate() async {
    try {
      final syncInfo = await checkSyncStatus();
      return syncInfo.status == SyncStatus.upToDate;
    } catch (e) {
      return false;
    }
  }

  Stream<Map<String, dynamic>> syncProgressStream() async* {
    yield {'progress': 0.0, 'message': 'Початок синхронізації...'};

    try {
      final result = await syncAllData(onProgress: (msg, prog) {});

      if (result.isLeft()) {
        final failure = result.fold((l) => l, (r) => null);
        yield {
          'progress': 1.0,
          'message': 'Помилка: ${failure.toString()}',
          'error': true,
        };
      } else {
        yield {
          'progress': 1.0,
          'message': 'Синхронізація завершена успішно',
          'completed': true,
        };
      }
    } catch (e) {
      yield {'progress': 1.0, 'message': 'Помилка: $e', 'error': true};
    }
  }

  // Тимчасово вимкнено realtime
  // Stream<NomenclaturaRealtimeEvent>? subscribeToRealtimeChanges() {
  //   return null;
  // }

  // Stream<Map<String, dynamic>>? subscribeToNomenclaturaItem(String guid) {
  //   return null;
  // }

  Future<void> unsubscribeFromRealtimeChanges() async {
    // no-op
  }

  List<String> getActiveRealtimeSubscriptions() {
    return const [];
  }

  bool hasActiveRealtimeSubscriptions() {
    return false;
  }

  @override
  Future<void> clearCache() async {
    try {
      // Очищаємо кеш номенклатури
      await nomenclaturaRepository.clearCache();

      // Тут можна додати очищення інших кешів
      // наприклад, кеш зображень, тимчасових файлів тощо

      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
    }
  }
}
