import 'package:flutter/material.dart';
import '../../domain/entities/sync_status_info.dart';
import '../../domain/constants/sync_constants.dart';
import '../../../../core/utils/sync_utils.dart';

class SyncStatisticsWidget extends StatelessWidget {
  final SyncStatusInfo? syncInfo;

  const SyncStatisticsWidget({super.key, this.syncInfo});

  @override
  Widget build(BuildContext context) {
    if (syncInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(SyncConstants.largePadding),
      decoration: BoxDecoration(
        color: SyncConstants.secondaryColor,
        borderRadius: BorderRadius.circular(SyncConstants.largeBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: SyncConstants.infoColor, size: 24),
              SizedBox(width: 12),
              Text('Статистика синхронізації', style: SyncConstants.titleStyle),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Загальна кількість',
                  '${syncInfo!.totalItems}',
                  Icons.inventory,
                  SyncConstants.infoColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Синхронізовано',
                  '${syncInfo!.syncedItems}',
                  Icons.check_circle,
                  SyncConstants.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (syncInfo!.lastSync != null)
            _buildStatItem(
              'Остання синхронізація',
              SyncUtils.formatLastSync(syncInfo!.lastSync!),
              Icons.access_time,
              SyncConstants.warningColor,
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SyncConstants.primaryColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SyncConstants.smallStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
