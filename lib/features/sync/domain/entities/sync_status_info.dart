import '../../../../core/services/sync/data_sync_service.dart';

class SyncStatusInfo {
  final bool isConnected;
  final DateTime? lastSync;
  final int totalItems;
  final int syncedItems;
  final String status;
  final SyncStatus syncStatus;
  final String? errorMessage;

  const SyncStatusInfo({
    required this.isConnected,
    this.lastSync,
    required this.totalItems,
    required this.syncedItems,
    required this.status,
    required this.syncStatus,
    this.errorMessage,
  });

  factory SyncStatusInfo.fromDataSyncInfo(DataSyncInfo syncInfo) {
    return SyncStatusInfo(
      isConnected: syncInfo.status != SyncStatus.noConnection,
      lastSync: syncInfo.lastSync,
      totalItems: syncInfo.localRecordsCount,
      syncedItems: syncInfo.localRecordsCount,
      status: _getStatusText(syncInfo.status),
      syncStatus: syncInfo.status,
      errorMessage: syncInfo.errorMessage,
    );
  }

  static String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.upToDate:
        return 'Дані актуальні';
      case SyncStatus.needsUpdate:
        return 'Потребує оновлення';
      case SyncStatus.noConnection:
        return 'Немає з\'єднання';
      case SyncStatus.noData:
        return 'Немає локальних даних';
      case SyncStatus.error:
        return 'Помилка при перевірці';
    }
  }

  bool get needsSync =>
      syncStatus == SyncStatus.needsUpdate || syncStatus == SyncStatus.noData;
  bool get canSync =>
      syncStatus != SyncStatus.noConnection && syncStatus != SyncStatus.error;
}
