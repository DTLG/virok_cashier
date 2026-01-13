import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/nomenclatura_model.dart';
import '../../../../core/services/data_sync_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/widgets/notificarion_toast/view.dart';

/// Widget для відображення списку номенклатури з realtime оновленнями
class RealtimeNomenclaturaList extends StatefulWidget {
  final List<NomenclaturaModel> initialData;
  final DataSyncService syncService;
  final Function(String)? onItemTapped;

  const RealtimeNomenclaturaList({
    super.key,
    required this.initialData,
    required this.syncService,
    this.onItemTapped,
  });

  @override
  State<RealtimeNomenclaturaList> createState() =>
      _RealtimeNomenclaturaListState();
}

class _RealtimeNomenclaturaListState extends State<RealtimeNomenclaturaList> {
  late List<NomenclaturaModel> _nomenclaturas;
  StreamSubscription<NomenclaturaRealtimeEvent>? _realtimeSubscription;
  final Set<String> _recentlyUpdatedItems = {};

  @override
  void initState() {
    super.initState();
    _nomenclaturas = List.from(widget.initialData);
    _subscribeToRealtimeChanges();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToRealtimeChanges() {
    // final realtimeStream = widget.syncService.subscribeToRealtimeChanges();
    // if (realtimeStream != null) {
    //   _realtimeSubscription = realtimeStream.listen(
    //     _handleRealtimeEvent,
    //     onError: (error) {
    //       print('Realtime error: $error');
    //       _showSnackBar('Помилка отримання оновлень: $error');
    //     },
    //   );
    // }
  }

  void _handleRealtimeEvent(NomenclaturaRealtimeEvent event) {
    final nomGuid = event.nomGuid;
    if (nomGuid == null) return;

    setState(() {
      if (event.isInsert) {
        _handleInsert(event);
      } else if (event.isUpdate) {
        _handleUpdate(event);
      } else if (event.isDelete) {
        _handleDelete(event);
      }

      // Додаємо до списку нещодавно оновлених
      _recentlyUpdatedItems.add(nomGuid);

      // Видаляємо через 3 секунди
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _recentlyUpdatedItems.remove(nomGuid);
          });
        }
      });
    });

    _showRealtimeNotification(event);
  }

  void _handleInsert(NomenclaturaRealtimeEvent event) {
    final newData = event.newData;
    if (newData == null) return;

    switch (event.type) {
      case NomenclaturaChangeType.nomenclatura:
        // Новий елемент номенклатури
        try {
          final nomenclaturaData = Map<String, dynamic>.from(newData);
          nomenclaturaData['prices'] = <Map<String, dynamic>>[];
          nomenclaturaData['barcodes'] = <Map<String, dynamic>>[];

          final newNomenclatura = NomenclaturaModel.fromJson(nomenclaturaData);
          _nomenclaturas.add(newNomenclatura);
          _sortNomenclaturas();
        } catch (e) {
          print('Error creating nomenclatura from realtime data: $e');
        }
        break;

      case NomenclaturaChangeType.prices:
      case NomenclaturaChangeType.barcodes:
        // Нові ціни або штрих-коди - оновлюємо відповідний елемент
        _updateRelatedData(event);
        break;
    }
  }

  void _handleUpdate(NomenclaturaRealtimeEvent event) {
    final nomGuid = event.nomGuid;
    if (nomGuid == null) return;

    switch (event.type) {
      case NomenclaturaChangeType.nomenclatura:
        // Оновлення номенклатури
        final index = _nomenclaturas.indexWhere((n) => n.guid == nomGuid);
        if (index != -1 && event.newData != null) {
          try {
            final updatedData = Map<String, dynamic>.from(event.newData!);
            // Зберігаємо існуючі ціни та штрих-коди
            // updatedData['prices'] = _nomenclaturas[index].prices
            //     .map((p) => p.toJson())
            //     .toList();
            // updatedData['barcodes'] = _nomenclaturas[index].barcodes
            //     .map((b) => b.toJson())
            //     .toList();

            _nomenclaturas[index] = NomenclaturaModel.fromJson(updatedData);
            _sortNomenclaturas();
          } catch (e) {
            print('Error updating nomenclatura from realtime data: $e');
          }
        }
        break;

      case NomenclaturaChangeType.prices:
      case NomenclaturaChangeType.barcodes:
        // Оновлення цін або штрих-кодів
        _updateRelatedData(event);
        break;
    }
  }

  void _handleDelete(NomenclaturaRealtimeEvent event) {
    final nomGuid = event.nomGuid;
    if (nomGuid == null) return;

    switch (event.type) {
      case NomenclaturaChangeType.nomenclatura:
        // Видалення номенклатури
        _nomenclaturas.removeWhere((n) => n.guid == nomGuid);
        break;

      case NomenclaturaChangeType.prices:
      case NomenclaturaChangeType.barcodes:
        // Видалення цін або штрих-кодів
        _updateRelatedData(event);
        break;
    }
  }

  void _updateRelatedData(NomenclaturaRealtimeEvent event) {
    final nomGuid = event.nomGuid;
    if (nomGuid == null) return;

    // Знаходимо відповідний елемент номенклатури
    final index = _nomenclaturas.indexWhere((n) => n.guid == nomGuid);
    if (index == -1) return;

    // Оновлюємо повністю з сервера (можна оптимізувати)
    _refreshNomenclaturaItem(nomGuid);
  }

  Future<void> _refreshNomenclaturaItem(String guid) async {
    // TODO: Додати метод до repository для отримання одного елемента
    // final result = await widget.syncService.nomenclaturaRepository
    //     .getNomenclaturaByGuid(guid);
    // Поки що просто позначаємо як оновлений
  }

  void _sortNomenclaturas() {
    _nomenclaturas.sort((a, b) {
      // Спочатку папки, потім товари
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.name.compareTo(b.name);
    });
  }

  void _showRealtimeNotification(NomenclaturaRealtimeEvent event) {
    final eventTypeText = event.isInsert
        ? 'додано'
        : event.isUpdate
        ? 'оновлено'
        : 'видалено';

    final typeText = event.type == NomenclaturaChangeType.nomenclatura
        ? 'Номенклатуру'
        : event.type == NomenclaturaChangeType.prices
        ? 'Ціни'
        : 'Штрих-коди';

    _showSnackBar('$typeText $eventTypeText в реальному часі');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ToastManager.show(context, type: ToastType.info, title: message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Індикатор realtime статусу
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.syncService.hasActiveRealtimeSubscriptions()
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.syncService.hasActiveRealtimeSubscriptions()
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.syncService.hasActiveRealtimeSubscriptions()
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: widget.syncService.hasActiveRealtimeSubscriptions()
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                widget.syncService.hasActiveRealtimeSubscriptions()
                    ? 'Realtime оновлення активні'
                    : 'Realtime оновлення відключені',
                style: TextStyle(
                  color: widget.syncService.hasActiveRealtimeSubscriptions()
                      ? Colors.green[700]
                      : Colors.orange[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Список номенклатури
        Expanded(
          child: ListView.builder(
            itemCount: _nomenclaturas.length,
            itemBuilder: (context, index) {
              final nomenclatura = _nomenclaturas[index];
              final isRecentlyUpdated = _recentlyUpdatedItems.contains(
                nomenclatura.guid,
              );

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isRecentlyUpdated
                      ? Colors.blue.withOpacity(0.1)
                      : null,
                  border: isRecentlyUpdated
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    nomenclatura.isFolder ? Icons.folder : Icons.inventory_2,
                    color: nomenclatura.isFolder
                        ? Colors.blue
                        : Colors.grey[600],
                  ),
                  title: Text(
                    nomenclatura.name,
                    style: TextStyle(
                      fontWeight: nomenclatura.isFolder
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isRecentlyUpdated ? Colors.blue[700] : null,
                    ),
                  ),
                  subtitle: Text(
                    nomenclatura.article.isNotEmpty
                        ? 'Артикул: ${nomenclatura.article}'
                        : nomenclatura.description ?? '',
                  ),
                  trailing: isRecentlyUpdated
                      ? const Icon(Icons.fiber_new, color: Colors.blue)
                      : null,
                  onTap: () => widget.onItemTapped?.call(nomenclatura.guid),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
