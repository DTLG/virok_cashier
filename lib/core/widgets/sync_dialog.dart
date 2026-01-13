import 'package:flutter/material.dart';
import '../services/data_sync_service.dart';

class SyncDialog extends StatefulWidget {
  final DataSyncInfo syncInfo;
  final DataSyncService syncService;

  const SyncDialog({
    super.key,
    required this.syncInfo,
    required this.syncService,
  });

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  bool _isLoading = false;
  String _currentMessage = '';
  double _progress = 0.0;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isLoading,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(_getStatusIcon(), color: _getStatusColor(), size: 24),
            const SizedBox(width: 8),
            const Text('Синхронізація даних'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusInfo(),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(
                  _currentMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: _buildActions(),
      ),
    );
  }

  Widget _buildStatusInfo() {
    final syncInfo = widget.syncInfo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getStatusMessage(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (syncInfo.localRecordsCount > 0)
          Text(
            'Локальних записів: ${syncInfo.localRecordsCount}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        if (syncInfo.lastSync != null)
          Text(
            'Остання синхронізація: ${_formatDateTime(syncInfo.lastSync!)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
      ],
    );
  }

  List<Widget> _buildActions() {
    if (_isLoading) {
      return [
        TextButton(onPressed: null, child: const Text('Синхронізація...')),
      ];
    }

    final actions = <Widget>[];

    // Кнопка "Пропустити" завжди доступна
    actions.add(
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Пропустити'),
      ),
    );

    // Кнопка "Примусова синхронізація" - очищає локальні дані та завантажує все заново
    if (widget.syncInfo.canSync) {
      actions.add(
        TextButton(
          onPressed: _forceSyncData,
          child: const Text('Примусова синхронізація'),
        ),
      );
    }

    // Кнопка "Синхронізувати" доступна якщо можна синхронізувати
    if (widget.syncInfo.canSync) {
      actions.add(
        ElevatedButton(
          onPressed: _syncData,
          child: const Text('Синхронізувати'),
        ),
      );
    }

    return actions;
  }

  IconData _getStatusIcon() {
    switch (widget.syncInfo.status) {
      case SyncStatus.upToDate:
        return Icons.check_circle;
      case SyncStatus.needsUpdate:
        return Icons.sync;
      case SyncStatus.noConnection:
        return Icons.wifi_off;
      case SyncStatus.noData:
        return Icons.download;
      case SyncStatus.error:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (widget.syncInfo.status) {
      case SyncStatus.upToDate:
        return Colors.green;
      case SyncStatus.needsUpdate:
        return Colors.orange;
      case SyncStatus.noConnection:
        return Colors.grey;
      case SyncStatus.noData:
        return Colors.blue;
      case SyncStatus.error:
        return Colors.red;
    }
  }

  String _getStatusMessage() {
    switch (widget.syncInfo.status) {
      case SyncStatus.upToDate:
        return 'Дані актуальні і готові до використання.';
      case SyncStatus.needsUpdate:
        return 'Дані застаріли і потребують оновлення для коректної роботи.';
      case SyncStatus.noConnection:
        return 'Немає з\'єднання з інтернетом. Можете працювати з локальними даними або спробувати пізніше.';
      case SyncStatus.noData:
        return 'Локальних даних немає. Потрібна синхронізація для початку роботи.';
      case SyncStatus.error:
        return 'Виникла помилка при перевірці даних: ${widget.syncInfo.errorMessage ?? "Невідома помилка"}';
    }
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

  Future<void> _syncData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _progress = 0.0;
      _currentMessage = 'Початок синхронізації...';
    });

    final result = await widget.syncService.syncAllData(
      onProgress: (message, progress) {
        setState(() {
          _currentMessage = message;
          _progress = progress;
        });
      },
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _errorMessage = failure.toString();
        });
      },
      (_) {
        setState(() {
          _isLoading = false;
          _currentMessage = 'Синхронізація завершена успішно!';
          _progress = 1.0;
        });

        // Закриваємо діалог через короткий час
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
             },
     );
   }

   Future<void> _forceSyncData() async {
     setState(() {
       _isLoading = true;
       _errorMessage = null;
       _progress = 0.0;
       _currentMessage = 'Початок примусової синхронізації...';
     });

     final result = await widget.syncService.forceSyncAllData(
       onProgress: (message, progress) {
         setState(() {
           _currentMessage = message;
           _progress = progress;
         });
       },
     );

     result.fold(
       (failure) {
         setState(() {
           _isLoading = false;
           _errorMessage = failure.toString();
         });
       },
       (_) {
         setState(() {
           _isLoading = false;
           _currentMessage = 'Примусова синхронізація завершена успішно!';
           _progress = 1.0;
         });

         // Закриваємо діалог через короткий час
         Future.delayed(const Duration(seconds: 1), () {
           if (mounted) {
             Navigator.of(context).pop(true);
           }
         });
       },
     );
   }
 }
 
 // Функція-помічник для показу діалогу
Future<bool?> showSyncDialog({
  required BuildContext context,
  required DataSyncInfo syncInfo,
  required DataSyncService syncService,
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        SyncDialog(syncInfo: syncInfo, syncService: syncService),
  );
}
