import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/sync/data_sync_service.dart';

/// Інтерфейс віддаленого джерела даних для синхронізації
abstract class SyncRemoteDataSource {
  Future<DataSyncInfo> checkSyncStatus();
  Future<Either<Failure, void>> syncAllData({
    void Function(String message, double progress)? onProgress,
  });
  Future<Either<Failure, void>> forceSyncAllData({
    void Function(String message, double progress)? onProgress,
  });
  Future<Either<Failure, int>> getServerRecordsCount();
  Future<Either<Failure, void>> syncSpecificData({
    bool syncNomenclatura,
    void Function(String message, double progress)? onProgress,
  });
  Future<Either<Failure, SyncStatistics>> getSyncStatistics();
  Future<Either<Failure, Map<String, dynamic>>> getDetailedSyncInfo();
}

class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final DataSyncService syncService;

  SyncRemoteDataSourceImpl({required this.syncService});

  @override
  Future<DataSyncInfo> checkSyncStatus() => syncService.checkSyncStatus();

  @override
  Future<Either<Failure, void>> forceSyncAllData({
    void Function(String message, double progress)? onProgress,
  }) => syncService.forceSyncAllData(onProgress: onProgress);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDetailedSyncInfo() =>
      syncService.getDetailedSyncInfo();

  @override
  Future<Either<Failure, int>> getServerRecordsCount() =>
      syncService.getServerRecordsCount();

  @override
  Future<Either<Failure, SyncStatistics>> getSyncStatistics() =>
      syncService.getSyncStatistics();

  @override
  Future<Either<Failure, void>> syncAllData({
    void Function(String message, double progress)? onProgress,
  }) => syncService.syncAllData(onProgress: onProgress);

  @override
  Future<Either<Failure, void>> syncSpecificData({
    bool syncNomenclatura = true,
    void Function(String message, double progress)? onProgress,
  }) => syncService.syncSpecificData(
    syncNomenclatura: syncNomenclatura,
    onProgress: onProgress,
  );
}
