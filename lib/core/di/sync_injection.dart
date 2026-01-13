import 'package:get_it/get_it.dart';
import '../../core/services/data_sync_service.dart';
import '../../features/sync/data/datasources/sync_local_data_source.dart';
import '../../features/sync/data/datasources/sync_remote_data_source.dart';
import '../../features/sync/data/repositories/sync_repository_impl.dart';
import '../../features/sync/domain/repositories/sync_repository.dart';
import '../../features/sync/domain/usecases/check_sync_status.dart';
import '../../features/sync/domain/usecases/perform_sync.dart';
import '../../features/sync/domain/usecases/get_detailed_sync_info.dart';
import '../../features/sync/domain/usecases/clear_local_data.dart';
import '../../features/sync/presentation/bloc/sync_bloc.dart';

final GetIt _sl = GetIt.instance;

void setupSyncInjection() {
  // Data sources
  _sl.registerLazySingleton<SyncRemoteDataSource>(
    () => SyncRemoteDataSourceImpl(syncService: _sl<DataSyncService>()),
  );
  _sl.registerLazySingleton<SyncLocalDataSource>(
    () => SyncLocalDataSourceImpl(
      clearAll: () => _sl<DataSyncService>().clearAllLocalData(),
    ),
  );

  // Repository
  _sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      remote: _sl<SyncRemoteDataSource>(),
      local: _sl<SyncLocalDataSource>(),
    ),
  );

  // Use Cases
  _sl.registerLazySingleton<CheckSyncStatus>(
    () => CheckSyncStatus(_sl<SyncRepository>()),
  );

  _sl.registerLazySingleton<PerformSync>(
    () => PerformSync(_sl<SyncRepository>()),
  );

  _sl.registerLazySingleton<GetDetailedSyncInfo>(
    () => GetDetailedSyncInfo(_sl<SyncRepository>()),
  );

  _sl.registerLazySingleton<ClearLocalData>(
    () => ClearLocalData(_sl<SyncRepository>()),
  );

  // BLoC
  _sl.registerFactory<SyncBloc>(
    () => SyncBloc(
      checkSyncStatus: _sl<CheckSyncStatus>(),
      performSync: _sl<PerformSync>(),
      getDetailedInfo: _sl<GetDetailedSyncInfo>(),
      clearLocalData: _sl<ClearLocalData>(),
    ),
  );
}
