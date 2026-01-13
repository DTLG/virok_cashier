import 'package:flutter/material.dart';
import '../services/enhanced_sync_service.dart';

class EnhancedSyncDialog extends StatefulWidget {
  final EnhancedSyncService syncService;

  const EnhancedSyncDialog({super.key, required this.syncService});

  @override
  State<EnhancedSyncDialog> createState() => _EnhancedSyncDialogState();
}

class _EnhancedSyncDialogState extends State<EnhancedSyncDialog> {
  EnhancedSyncInfo? _syncInfo;
  bool _isLoading = false;
  String _currentOperation = '';
  double _progress = 0.0;
  List<SyncOperation> _availableOperations = [];
  Set<String> _selectedOperations = {'nomenclatura'};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      final syncInfo = await widget.syncService.getSyncInfo();
      final operations = await widget.syncService.getAvailableOperations();

      setState(() {
        _syncInfo = syncInfo;
        _availableOperations = operations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSync() async {
    if (_selectedOperations.isEmpty) return;

    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _currentOperation = '';
    });

    try {
      final result = await widget.syncService.performSync(
        operations: _selectedOperations.toList(),
        onProgress: (operation, progress) {
          setState(() {
            _currentOperation = operation;
            _progress = progress;
          });
        },
      );

      result.fold(
        (failure) {
          _showErrorDialog(failure.toString());
        },
        (_) {
          _showSuccessDialog();
          _loadInitialData(); // Оновити інформацію
        },
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
        _progress = 0.0;
      });
    }
  }

  Future<void> _performQuickSync() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _currentOperation = '';
    });

    try {
      final result = await widget.syncService.performQuickSync(
        onProgress: (operation, progress) {
          setState(() {
            _currentOperation = operation;
            _progress = progress;
          });
        },
      );

      result.fold(
        (failure) {
          _showErrorDialog(failure.toString());
        },
        (_) {
          _showSuccessDialog();
          _loadInitialData();
        },
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
        _progress = 0.0;
      });
    }
  }

  Future<void> _performFullSync() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
      _currentOperation = '';
    });

    try {
      final result = await widget.syncService.performFullSync(
        onProgress: (operation, progress) {
          setState(() {
            _currentOperation = operation;
            _progress = progress;
          });
        },
      );

      result.fold(
        (failure) {
          _showErrorDialog(failure.toString());
        },
        (_) {
          _showSuccessDialog();
          _loadInitialData();
        },
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
        _currentOperation = '';
        _progress = 0.0;
      });
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Помилка синхронізації',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(error, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Синхронізація завершена',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Дані успішно синхронізовано',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(Icons.sync, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Синхронізація даних',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_isLoading && _syncInfo == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Статус
              if (_syncInfo != null) _buildStatusSection(),

              const SizedBox(height: 24),

              // Операції
              _buildOperationsSection(),

              const SizedBox(height: 24),

              // Прогрес
              if (_isLoading) _buildProgressSection(),

              const SizedBox(height: 24),

              // Кнопки
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    final info = _syncInfo!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(info.status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(info.status),
                color: _getStatusColor(info.status),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(info.status),
                style: TextStyle(
                  color: _getStatusColor(info.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Підключення',
                  info.isConnected ? 'Підключено' : 'Відключено',
                  info.isConnected ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  'Локальні дані',
                  '${info.totalItems}',
                  Colors.blue,
                ),
              ),
            ],
          ),
          if (info.lastSyncTime != null) ...[
            const SizedBox(height: 8),
            _buildStatusItem(
              'Остання синхронізація',
              _formatLastSync(info.lastSyncTime!),
              Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Операції синхронізації',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ..._availableOperations.map(
          (operation) => _buildOperationTile(operation),
        ),
      ],
    );
  }

  Widget _buildOperationTile(SyncOperation operation) {
    final isSelected = _selectedOperations.contains(operation.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: operation.isEnabled
            ? (value) {
                setState(() {
                  if (value == true) {
                    _selectedOperations.add(operation.id);
                  } else {
                    _selectedOperations.remove(operation.id);
                  }
                });
              }
            : null,
        title: Text(
          operation.name,
          style: TextStyle(
            color: operation.isEnabled ? Colors.white : Colors.white54,
          ),
        ),
        subtitle: Text(
          operation.description,
          style: TextStyle(
            color: operation.isEnabled ? Colors.white70 : Colors.white38,
          ),
        ),
        secondary: Icon(
          operation.icon,
          color: operation.isEnabled ? Colors.blue : Colors.white38,
        ),
        activeColor: Colors.blue,
        checkColor: Colors.white,
        tileColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                _currentOperation.isNotEmpty
                    ? _currentOperation
                    : 'Синхронізація...',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toInt()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _performQuickSync,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
            child: const Text('Швидка синхронізація'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _performSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Синхронізувати'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _performFullSync,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
            child: const Text('Повна синхронізація'),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.upToDate:
        return Colors.green;
      case SyncStatus.needsUpdate:
        return Colors.orange;
      case SyncStatus.noConnection:
        return Colors.red;
      case SyncStatus.noData:
        return Colors.blue;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.syncing:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.upToDate:
        return Icons.check_circle;
      case SyncStatus.needsUpdate:
        return Icons.update;
      case SyncStatus.noConnection:
        return Icons.wifi_off;
      case SyncStatus.noData:
        return Icons.inventory;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.syncing:
        return Icons.sync;
    }
  }

  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.upToDate:
        return 'Дані актуальні';
      case SyncStatus.needsUpdate:
        return 'Потребує оновлення';
      case SyncStatus.noConnection:
        return 'Немає з\'єднання';
      case SyncStatus.noData:
        return 'Немає даних';
      case SyncStatus.error:
        return 'Помилка';
      case SyncStatus.syncing:
        return 'Синхронізація';
    }
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Щойно';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} хв тому';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} год тому';
    } else {
      return '${difference.inDays} дн тому';
    }
  }
}

Future<bool?> showEnhancedSyncDialog({
  required BuildContext context,
  required EnhancedSyncService syncService,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => EnhancedSyncDialog(syncService: syncService),
  );
}
