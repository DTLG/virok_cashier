import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_sync_status.dart';
import '../../domain/usecases/perform_sync.dart';
import '../../domain/usecases/get_detailed_sync_info.dart';
import '../../domain/usecases/clear_local_data.dart';
import '../../domain/entities/sync_status_info.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final CheckSyncStatus _checkSyncStatus;
  final PerformSync _performSync;
  final GetDetailedSyncInfo _getDetailedInfo;
  final ClearLocalData _clearLocalData;

  SyncBloc({
    required CheckSyncStatus checkSyncStatus,
    required PerformSync performSync,
    required GetDetailedSyncInfo getDetailedInfo,
    required ClearLocalData clearLocalData,
  }) : _checkSyncStatus = checkSyncStatus,
       _performSync = performSync,
       _getDetailedInfo = getDetailedInfo,
       _clearLocalData = clearLocalData,
       super(SyncInitial()) {
    on<CheckSyncStatusEvent>(_onCheckSyncStatus);
    on<PerformSyncEvent>(_onPerformSync);
    on<GetDetailedInfoEvent>(_onGetDetailedInfo);
    on<ClearLocalDataEvent>(_onClearLocalData);
    on<ResetSyncStateEvent>(_onResetSyncState);
  }

  Future<void> _onCheckSyncStatus(
    CheckSyncStatusEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(SyncLoading(message: 'Перевірка статусу синхронізації...'));

    final result = await _checkSyncStatus();

    result.fold(
      (failure) => emit(SyncError('Помилка перевірки: ${failure.toString()}')),
      (syncInfo) =>
          emit(SyncStatusLoaded(SyncStatusInfo.fromDataSyncInfo(syncInfo))),
    );
  }

  Future<void> _onPerformSync(
    PerformSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(
      SyncLoading(
        message: event.forceSync
            ? 'Примусова синхронізація...'
            : 'Синхронізація...',
      ),
    );

    final result = await _performSync(
      forceSync: event.forceSync,
      onProgress: (message, progress) {
        emit(SyncInProgress(message: message, progress: progress));
      },
    );

    result.fold(
      (failure) =>
          emit(SyncError('Помилка синхронізації: ${failure.toString()}')),
      (_) => emit(
        SyncCompleted(
          message: event.forceSync
              ? 'Примусова синхронізація завершена'
              : 'Синхронізація завершена',
        ),
      ),
    );
  }

  Future<void> _onGetDetailedInfo(
    GetDetailedInfoEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(SyncLoading(message: 'Отримання детальної інформації...'));

    final result = await _getDetailedInfo();

    result.fold(
      (failure) => emit(
        SyncError('Помилка отримання інформації: ${failure.toString()}'),
      ),
      (info) => emit(DetailedInfoLoaded(info)),
    );
  }

  Future<void> _onClearLocalData(
    ClearLocalDataEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(SyncLoading(message: 'Очищення локальних даних...'));

    final result = await _clearLocalData();

    result.fold(
      (failure) => emit(SyncError('Помилка очищення: ${failure.toString()}')),
      (_) => emit(LocalDataCleared()),
    );
  }

  void _onResetSyncState(ResetSyncStateEvent event, Emitter<SyncState> emit) {
    emit(SyncInitial());
  }
}
