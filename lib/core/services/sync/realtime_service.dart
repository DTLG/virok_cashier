import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Сервіс для роботи з realtime змінами в Supabase
class RealtimeService {
  final SupabaseClient _supabaseClient;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController> _controllers = {};

  RealtimeService(this._supabaseClient);

  /// Підписується на зміни в таблиці номенклатури
  Stream<Map<String, dynamic>> subscribeToNomenclaturaChanges() {
    const channelName = 'nomenclatura_changes';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    final channel = _supabaseClient
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'kup',
          table: 'nomenklatura',
          callback: (payload) {
            print(
              'Nomenclatura change detected: ${payload.eventType} - ${payload.newRecord}',
            );
            final event = {
              'type': 'nomenclatura',
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            };
            controller.add(event);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Підписується на зміни в таблиці цін
  Stream<Map<String, dynamic>> subscribeToPricesChanges() {
    const channelName = 'prices_changes';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    final channel = _supabaseClient
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'kup',
          table: 'prices',
          callback: (payload) {
            print(
              'Prices change detected: ${payload.eventType} - ${payload.newRecord}',
            );
            final event = {
              'type': 'prices',
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            };
            controller.add(event);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Підписується на зміни в таблиці штрих-кодів
  Stream<Map<String, dynamic>> subscribeToBarcodesChanges() {
    const channelName = 'barcodes_changes';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    final channel = _supabaseClient
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'kup',
          table: 'barcodes',
          callback: (payload) {
            print(
              'Barcodes change detected: ${payload.eventType} - ${payload.newRecord}',
            );
            final event = {
              'type': 'barcodes',
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
            };
            controller.add(event);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Підписується на зміни конкретного елемента номенклатури за GUID
  Stream<Map<String, dynamic>> subscribeToNomenclaturaByGuid(String guid) {
    final channelName = 'nomenclatura_$guid';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    final channel = _supabaseClient
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'kup',
          table: 'nomenklatura',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'guid',
            value: guid,
          ),
          callback: (payload) {
            print('Nomenclatura $guid change detected: ${payload.eventType}');
            final event = {
              'type': 'nomenclatura',
              'eventType': payload.eventType.name,
              'newRecord': payload.newRecord,
              'oldRecord': payload.oldRecord,
              'guid': guid,
            };
            controller.add(event);
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    return controller.stream;
  }

  /// Комбінований stream для всіх змін що впливають на номенклатуру
  Stream<NomenclaturaRealtimeEvent> subscribeToAllNomenclaturaRelatedChanges() {
    final controller = StreamController<NomenclaturaRealtimeEvent>.broadcast();

    // Підписуємось на всі три таблиці
    subscribeToNomenclaturaChanges().listen((event) {
      controller.add(
        NomenclaturaRealtimeEvent(
          type: NomenclaturaChangeType.nomenclatura,
          eventType: event['eventType'] as String,
          newData: event['newRecord'] as Map<String, dynamic>?,
          oldData: event['oldRecord'] as Map<String, dynamic>?,
        ),
      );
    });

    subscribeToPricesChanges().listen((event) {
      controller.add(
        NomenclaturaRealtimeEvent(
          type: NomenclaturaChangeType.prices,
          eventType: event['eventType'] as String,
          newData: event['newRecord'] as Map<String, dynamic>?,
          oldData: event['oldRecord'] as Map<String, dynamic>?,
        ),
      );
    });

    subscribeToBarcodesChanges().listen((event) {
      controller.add(
        NomenclaturaRealtimeEvent(
          type: NomenclaturaChangeType.barcodes,
          eventType: event['eventType'] as String,
          newData: event['newRecord'] as Map<String, dynamic>?,
          oldData: event['oldRecord'] as Map<String, dynamic>?,
        ),
      );
    });

    return controller.stream;
  }

  /// Відписується від конкретного каналу
  Future<void> unsubscribe(String channelName) async {
    if (_channels.containsKey(channelName)) {
      await _supabaseClient.removeChannel(_channels[channelName]!);
      _channels.remove(channelName);
    }

    if (_controllers.containsKey(channelName)) {
      await _controllers[channelName]!.close();
      _controllers.remove(channelName);
    }
  }

  /// Відписується від всіх каналів
  Future<void> unsubscribeAll() async {
    for (final channelName in _channels.keys.toList()) {
      await unsubscribe(channelName);
    }
  }

  /// Перевіряє стан підключення
  bool isSubscribed(String channelName) {
    return _channels.containsKey(channelName);
  }

  /// Отримує список активних підписок
  List<String> getActiveSubscriptions() {
    return _channels.keys.toList();
  }

  /// Перевіряє чи канал підключений
  bool isChannelConnected(String channelName) {
    return _channels.containsKey(channelName);
  }

  /// Отримує кількість активних каналів
  int getActiveChannelCount() {
    return _channels.length;
  }
}

/// Типи змін в номенклатурі
enum NomenclaturaChangeType { nomenclatura, prices, barcodes }

/// Подія зміни в номенклатурі
class NomenclaturaRealtimeEvent {
  final NomenclaturaChangeType type;
  final String eventType;
  final Map<String, dynamic>? newData;
  final Map<String, dynamic>? oldData;

  NomenclaturaRealtimeEvent({
    required this.type,
    required this.eventType,
    this.newData,
    this.oldData,
  });

  /// Отримує GUID номенклатури з payload
  String? get nomGuid {
    switch (type) {
      case NomenclaturaChangeType.nomenclatura:
        return newData?['guid'] ?? oldData?['guid'];
      case NomenclaturaChangeType.prices:
      case NomenclaturaChangeType.barcodes:
        return newData?['nom_guid'] ?? oldData?['nom_guid'];
    }
  }

  /// Перевіряє чи це INSERT подія
  bool get isInsert => eventType.toLowerCase() == 'insert';

  /// Перевіряє чи це UPDATE подія
  bool get isUpdate => eventType.toLowerCase() == 'update';

  /// Перевіряє чи це DELETE подія
  bool get isDelete => eventType.toLowerCase() == 'delete';

  @override
  String toString() {
    return 'NomenclaturaRealtimeEvent{type: $type, eventType: $eventType, nomGuid: $nomGuid}';
  }
}
