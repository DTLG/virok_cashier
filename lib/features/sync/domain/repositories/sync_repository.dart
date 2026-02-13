import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/sync/data_sync_service.dart';

/// Абстракція репозиторію синхронізації для Clean Architecture
abstract class SyncRepository {
  Future<DataSyncInfo> checkSyncStatus();

  Future<Either<Failure, void>> syncAllData({
    void Function(String message, double progress)? onProgress,
  });

  Future<Either<Failure, void>> forceSyncAllData({
    void Function(String message, double progress)? onProgress,
  });

  Future<bool> hasInternetConnection();

  Future<Either<Failure, int>> getServerRecordsCount();

  Future<Either<Failure, void>> syncSpecificData({
    bool syncNomenclatura,
    void Function(String message, double progress)? onProgress,
  });

  Future<Either<Failure, void>> clearAllLocalData();

  Future<Either<Failure, SyncStatistics>> getSyncStatistics();

  Future<Either<Failure, Map<String, dynamic>>> getDetailedSyncInfo();
}
