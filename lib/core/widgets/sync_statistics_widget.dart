import 'package:flutter/material.dart';
import 'package:cash_register/core/services/sync/data_sync_service.dart';
import 'package:cash_register/core/widgets/notificarion_toast/view.dart';

class SyncStatisticsWidget extends StatefulWidget {
  final DataSyncService syncService;

  const SyncStatisticsWidget({super.key, required this.syncService});

  @override
  State<SyncStatisticsWidget> createState() => _SyncStatisticsWidgetState();
}

class _SyncStatisticsWidgetState extends State<SyncStatisticsWidget> {
  SyncStatistics? _statistics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.syncService.getSyncStatistics();

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.toString();
        });
      },
      (statistics) {
        setState(() {
          _isLoading = false;
          _statistics = statistics;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Завантаження статистики...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.red[600], size: 32),
              const SizedBox(height: 8),
              Text(
                'Помилка завантаження статистики',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadStatistics,
                child: const Text('Спробувати ще раз'),
              ),
            ],
          ),
        ),
      );
    }

    if (_statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Статистика недоступна'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Статистика синхронізації',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadStatistics,
                  tooltip: 'Оновити статистику',
                ),
              ],
            ),
            const Divider(),
            _buildStatisticRow(
              icon: Icons.storage,
              label: 'Локальних записів',
              value: '${_statistics!.localRecordsCount}',
              color: Colors.blue,
            ),
            if (_statistics!.serverRecordsCount != null)
              _buildStatisticRow(
                icon: Icons.cloud,
                label: 'Записів на сервері',
                value: '${_statistics!.serverRecordsCount}',
                color: Colors.green,
              ),
            if (_statistics!.lastSuccessfulSync != null)
              _buildStatisticRow(
                icon: Icons.access_time,
                label: 'Остання синхронізація',
                value: _formatDateTime(_statistics!.lastSuccessfulSync!),
                color: Colors.orange,
              ),
            if (_statistics!.timeSinceLastSync != null)
              _buildStatisticRow(
                icon: Icons.schedule,
                label: 'Часу з останньої синхронізації',
                value: _formatDuration(_statistics!.timeSinceLastSync!),
                color: _getDurationColor(_statistics!.timeSinceLastSync!),
              ),
            if (_statistics!.recentErrors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Останні помилки:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.red[700]),
              ),
              ..._statistics!.recentErrors
                  .take(3)
                  .map(
                    (error) => Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                      child: Text(
                        '• $error',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.red[600]),
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sync,
                    label: 'Швидка синхронізація',
                    onPressed: _quickSync,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.sync_disabled,
                    label: 'Очистити дані',
                    onPressed: _clearData,
                    isDestructive: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red[50] : null,
        foregroundColor: isDestructive ? Colors.red[700] : null,
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} днів тому';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} годин тому';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} хвилин тому';
    } else {
      return 'Щойно';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} днів';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} годин';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} хвилин';
    } else {
      return 'менше хвилини';
    }
  }

  Color _getDurationColor(Duration duration) {
    if (duration.inHours > 24) {
      return Colors.red; // Більше доби - критично
    } else if (duration.inHours > 12) {
      return Colors.orange; // Більше 12 годин - попередження
    } else {
      return Colors.green; // Менше 12 годин - нормально
    }
  }

  Future<void> _quickSync() async {
    final result = await widget.syncService.syncAllData();

    result.fold(
      (failure) {
        if (mounted) {
          ToastManager.show(
            context,
            type: ToastType.error,
            title: 'Помилка синхронізації: ${failure.toString()}',
          );
        }
      },
      (_) {
        if (mounted) {
          ToastManager.show(
            context,
            type: ToastType.success,
            title: 'Синхронізація завершена успішно',
          );

          _loadStatistics(); // Оновлюємо статистику
        }
      },
    );
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Підтвердження'),
        content: const Text(
          'Ви впевнені, що хочете очистити всі локальні дані? '
          'Це незворотна дія, і дані доведеться завантажувати заново.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Очистити'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await widget.syncService.clearAllLocalData();

      result.fold(
        (failure) {
          if (mounted) {
            ToastManager.show(
              context,
              type: ToastType.error,
              title: 'Помилка очищення: ${failure.toString()}',
            );
          }
        },
        (_) {
          if (mounted) {
            ToastManager.show(
              context,
              type: ToastType.success,
              title: 'Дані очищено успішно',
            );
            _loadStatistics(); // Оновлюємо статистику
          }
        },
      );
    }
  }
}
