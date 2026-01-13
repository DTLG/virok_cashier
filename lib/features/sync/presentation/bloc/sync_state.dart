import '../../domain/entities/sync_status_info.dart';

abstract class SyncState {}

class SyncInitial extends SyncState {}

class SyncLoading extends SyncState {
  final String message;

  SyncLoading({this.message = 'Завантаження...'});
}

class SyncStatusLoaded extends SyncState {
  final SyncStatusInfo syncInfo;

  SyncStatusLoaded(this.syncInfo);
}

class SyncInProgress extends SyncState {
  final String message;
  final double progress;

  SyncInProgress({required this.message, required this.progress});
}

class SyncCompleted extends SyncState {
  final String message;

  SyncCompleted({this.message = 'Синхронізація завершена'});
}

class SyncError extends SyncState {
  final String message;

  SyncError(this.message);
}

class DetailedInfoLoaded extends SyncState {
  final Map<String, dynamic> detailedInfo;

  DetailedInfoLoaded(this.detailedInfo);
}

class LocalDataCleared extends SyncState {
  final String message;

  LocalDataCleared({this.message = 'Локальні дані очищено'});
}
