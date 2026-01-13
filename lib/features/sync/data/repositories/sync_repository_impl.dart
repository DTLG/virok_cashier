import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_data_source.dart';
import '../datasources/sync_remote_data_source.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncRemoteDataSource remote;
  final SyncLocalDataSource local;

  SyncRepositoryImpl({required this.remote, required this.local});

  @override
  Future<DataSyncInfo> checkSyncStatus() => remote.checkSyncStatus();

  @override
  Future<Either<Failure, void>> clearAllLocalData() =>
      local.clearAllLocalData();

  @override
  Future<Either<Failure, void>> forceSyncAllData({
    void Function(String message, double progress)? onProgress,
  }) => remote.forceSyncAllData(onProgress: onProgress);

  @override
  Future<bool> hasInternetConnection() async {
    final info = await remote.checkSyncStatus();
    return info.status != SyncStatus.noConnection;
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDetailedSyncInfo() =>
      remote.getDetailedSyncInfo();

  @override
  Future<Either<Failure, int>> getServerRecordsCount() =>
      remote.getServerRecordsCount();

  @override
  Future<Either<Failure, SyncStatistics>> getSyncStatistics() =>
      remote.getSyncStatistics();

  @override
  Future<Either<Failure, void>> syncAllData({
    void Function(String message, double progress)? onProgress,
  }) => remote.syncAllData(onProgress: onProgress);

  @override
  Future<Either<Failure, void>> syncSpecificData({
    bool syncNomenclatura = true,
    void Function(String message, double progress)? onProgress,
  }) => remote.syncSpecificData(
    syncNomenclatura: syncNomenclatura,
    onProgress: onProgress,
  );
}
