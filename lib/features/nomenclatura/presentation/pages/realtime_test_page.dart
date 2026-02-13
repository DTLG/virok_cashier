import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/services/sync/app_initialization_service.dart';
import '../../../../core/services/sync/realtime_service.dart';
import '../../../../core/services/sync/data_sync_service.dart';

/// Сторінка для тестування realtime функціональності
class RealtimeTestPage extends StatefulWidget {
  const RealtimeTestPage({super.key});

  @override
  State<RealtimeTestPage> createState() => _RealtimeTestPageState();
}

class _RealtimeTestPageState extends State<RealtimeTestPage> {
  late RealtimeService _realtimeService;
  late DataSyncService _syncService;
  StreamSubscription<NomenclaturaRealtimeEvent>? _realtimeSubscription;

  final List<String> _realtimeEvents = [];
  final ScrollController _scrollController = ScrollController();
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _realtimeService = AppInitializationService.get<RealtimeService>();
    _syncService = AppInitializationService.get<DataSyncService>();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.unsubscribeAll();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleRealtimeSubscription() {
    if (_isSubscribed) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _isSubscribed = true;
      _realtimeEvents.add(
        '[${DateTime.now().toIso8601String()}] Підписка активована',
      );
    });

    _realtimeSubscription = _realtimeService
        .subscribeToAllNomenclaturaRelatedChanges()
        .listen(
          (event) {
            setState(() {
              final timestamp = DateTime.now().toIso8601String();
              final message =
                  '[${timestamp}] ${event.type.name.toUpperCase()}: ${event.eventType} - GUID: ${event.nomGuid}';
              _realtimeEvents.add(message);

              if (event.newData != null) {
                _realtimeEvents.add(
                  '   Нові дані: ${event.newData.toString()}',
                );
              }
              if (event.oldData != null) {
                _realtimeEvents.add(
                  '   Старі дані: ${event.oldData.toString()}',
                );
              }
            });

            // Прокручуємо до кінця
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          },
          onError: (error) {
            setState(() {
              _realtimeEvents.add(
                '[${DateTime.now().toIso8601String()}] ПОМИЛКА: $error',
              );
            });
          },
        );
  }

  void _stopListening() {
    setState(() {
      _isSubscribed = false;
      _realtimeEvents.add(
        '[${DateTime.now().toIso8601String()}] Підписка деактивована',
      );
    });

    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
  }

  void _clearEvents() {
    setState(() {
      _realtimeEvents.clear();
    });
  }

  void _testConnection() {
    setState(() {
      final activeSubscriptions = _realtimeService.getActiveSubscriptions();
      final channelCount = _realtimeService.getActiveChannelCount();

      _realtimeEvents.add(
        '[${DateTime.now().toIso8601String()}] Статус з\'єднання:',
      );
      _realtimeEvents.add('   Активних каналів: $channelCount');
      _realtimeEvents.add('   Підписки: ${activeSubscriptions.join(', ')}');
      final realtimeSubscriptions = _realtimeService.getActiveSubscriptions();
      _realtimeEvents.add(
        '   Realtime підписки: ${realtimeSubscriptions.join(', ')}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearEvents,
            tooltip: 'Очистити події',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель управління
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleRealtimeSubscription,
                        icon: Icon(
                          _isSubscribed ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(
                          _isSubscribed
                              ? 'Зупинити підписку'
                              : 'Почати підписку',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSubscribed
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _testConnection,
                      icon: const Icon(Icons.network_check),
                      label: const Text('Статус'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Індикатор стану
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isSubscribed
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isSubscribed ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSubscribed
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _isSubscribed ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSubscribed
                            ? 'Realtime активний'
                            : 'Realtime неактивний',
                        style: TextStyle(
                          color: _isSubscribed
                              ? Colors.green[700]
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Події: ${_realtimeEvents.length}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Список подій
          Expanded(
            child: _realtimeEvents.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Немає подій для відображення',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Натисніть "Почати підписку" для тестування',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _realtimeEvents.length,
                    itemBuilder: (context, index) {
                      final event = _realtimeEvents[index];
                      final isError = event.contains('ПОМИЛКА');
                      final isInfo =
                          event.contains('Статус') ||
                          event.contains('підписка') ||
                          event.contains('Активних');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isError
                              ? Colors.red.withOpacity(0.1)
                              : isInfo
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isError
                                ? Colors.red
                                : isInfo
                                ? Colors.blue
                                : Colors.green,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          event,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isError
                                ? Colors.red[700]
                                : isInfo
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
