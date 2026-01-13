abstract class SyncEvent {}

class CheckSyncStatusEvent extends SyncEvent {}

class PerformSyncEvent extends SyncEvent {
  final bool forceSync;
  final void Function(String message, double progress)? onProgress;

  PerformSyncEvent({this.forceSync = false, this.onProgress});
}

class GetDetailedInfoEvent extends SyncEvent {}

class ClearLocalDataEvent extends SyncEvent {}

class ResetSyncStateEvent extends SyncEvent {}
