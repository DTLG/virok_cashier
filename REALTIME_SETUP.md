# Налаштування Realtime функціональності

## Огляд

Realtime функціональність дозволяє отримувати оновлення в реальному часі коли дані змінюються в базі даних Supabase. Це базується на PostgreSQL's logical replication.

✅ **СТАТУС: ІМПЛЕМЕНТОВАНО**
- RealtimeService створено для Supabase SDK 2.8.0
- Інтеграція з DataSyncService завершена
- Тестова сторінка додана до додатку
- SQL скрипт для налаштування готовий

## Архітектура

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Supabase      │    │  RealtimeService │    │    Flutter      │
│   Database      │───▶│                  │───▶│    Widgets      │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                        │                        │
        │                        │                        │
        ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Logical         │    │ Stream           │    │ UI Updates      │
│ Replication     │    │ Controllers      │    │ & Animations    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 1. Налаштування в Supabase

### Крок 1: Активація Realtime для таблиць

В Supabase Dashboard -> Database -> Replication:

```sql
-- Увімкнути realtime для таблиць
ALTER PUBLICATION supabase_realtime ADD TABLE nomenklatura;
ALTER PUBLICATION supabase_realtime ADD TABLE prices;
ALTER PUBLICATION supabase_realtime ADD TABLE barcodes;
```

### Крок 2: Налаштування Row Level Security (RLS)

```sql
-- Увімкнути RLS для таблиць
ALTER TABLE nomenklatura ENABLE ROW LEVEL SECURITY;
ALTER TABLE prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE barcodes ENABLE ROW LEVEL SECURITY;

-- Створити політики для читання (можна налаштувати згідно ваших потреб)
CREATE POLICY "Enable read access for all users" ON nomenklatura 
    FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON prices 
    FOR SELECT USING (true);

CREATE POLICY "Enable read access for all users" ON barcodes 
    FOR SELECT USING (true);
```

## 2. Flutter Implementation

### RealtimeService

`RealtimeService` надає методи для:

- **Підписка на зміни**: `subscribeToNomenclaturaChanges()`, `subscribeToPricesChanges()`, `subscribeToBarcodesChanges()`
- **Фільтрація**: `subscribeToNomenclaturaByGuid(guid)` - підписка на конкретний елемент
- **Комбінований stream**: `subscribeToAllNomenclaturaRelatedChanges()` - всі зміни в одному stream
- **Управління підписками**: `unsubscribe()`, `unsubscribeAll()`, `getActiveSubscriptions()`

### Типи подій

```dart
enum NomenclaturaChangeType {
  nomenclatura,  // Зміни в таблиці nomenklatura
  prices,        // Зміни в таблиці prices
  barcodes,      // Зміни в таблиці barcodes
}
```

### Payload структура

```dart
class NomenclaturaRealtimeEvent {
  final NomenclaturaChangeType type;    // Тип зміни
  final RealtimePayload payload;        // Дані від Supabase
  
  String? get nomGuid;                  // GUID номенклатури
  String get eventType;                 // INSERT/UPDATE/DELETE
  Map<String, dynamic>? get newData;    // Нові дані
  Map<String, dynamic>? get oldData;    // Старі дані (для UPDATE/DELETE)
}
```

## 3. Приклади використання

### Основна підписка

```dart
final realtimeService = GetIt.instance<RealtimeService>();

// Підписка на всі зміни
final subscription = realtimeService
    .subscribeToAllNomenclaturaRelatedChanges()
    .listen((event) {
  
  print('Зміна: ${event.eventType} в ${event.type}');
  
  switch (event.type) {
    case NomenclaturaChangeType.nomenclatura:
      _handleNomenclaturaChange(event);
      break;
    case NomenclaturaChangeType.prices:
      _handlePricesChange(event);
      break;
    case NomenclaturaChangeType.barcodes:
      _handleBarcodesChange(event);
      break;
  }
});

// Не забудьте відписатися
subscription.cancel();
```

### Підписка на конкретний елемент

```dart
final itemSubscription = realtimeService
    .subscribeToNomenclaturaByGuid('specific-guid-here')
    .listen((payload) {
  
  print('Елемент оновлено: ${payload.newRecord}');
  _updateUIForSpecificItem(payload);
});
```

### Використання в Widget

```dart
class MyNomenclaturaWidget extends StatefulWidget {
  // ... widget code
}

class _MyNomenclaturaWidgetState extends State<MyNomenclaturaWidget> {
  StreamSubscription<NomenclaturaRealtimeEvent>? _realtimeSubscription;
  List<NomenclaturaModel> _items = [];

  @override
  void initState() {
    super.initState();
    _subscribeToRealtime();
  }

  void _subscribeToRealtime() {
    final syncService = GetIt.instance<DataSyncService>();
    _realtimeSubscription = syncService
        .subscribeToRealtimeChanges()
        ?.listen(_handleRealtimeUpdate);
  }

  void _handleRealtimeUpdate(NomenclaturaRealtimeEvent event) {
    setState(() {
      switch (event.payload.eventType) {
        case PostgresChangeEvent.insert:
          _addNewItem(event);
          break;
        case PostgresChangeEvent.update:
          _updateExistingItem(event);
          break;
        case PostgresChangeEvent.delete:
          _removeItem(event);
          break;
      }
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
```

## 4. Інтеграція з DataSyncService

`DataSyncService` включає методи для роботи з realtime:

```dart
final syncService = GetIt.instance<DataSyncService>();

// Підписка на зміни
final stream = syncService.subscribeToRealtimeChanges();

// Перевірка статусу
bool isConnected = syncService.hasActiveRealtimeSubscriptions();

// Отримання списку підписок
List<String> subscriptions = syncService.getActiveRealtimeSubscriptions();

// Відписка
await syncService.unsubscribeFromRealtimeChanges();
```

## 5. Обробка помилок

```dart
_realtimeSubscription = realtimeService
    .subscribeToAllNomenclaturaRelatedChanges()
    .listen(
      _handleRealtimeEvent,
      onError: (error) {
        print('Realtime error: $error');
        _showErrorDialog('Помилка з\'єднання: $error');
        
        // Спробувати перепідключитися через деякий час
        Timer(Duration(seconds: 5), () {
          _subscribeToRealtime();
        });
      },
    );
```

## 6. Оптимізація продуктивності

### Селективна підписка

```dart
// Замість підписки на всі зміни
// realtimeService.subscribeToAllNomenclaturaRelatedChanges()

// Підписуйтесь тільки на те що потрібно
realtimeService.subscribeToNomenclaturaChanges()  // Тільки номенклатура
```

### Batch оновлення

```dart
Timer? _updateTimer;
Set<String> _pendingUpdates = {};

void _handleRealtimeUpdate(NomenclaturaRealtimeEvent event) {
  _pendingUpdates.add(event.nomGuid ?? '');
  
  // Batch оновлення кожні 500мс
  _updateTimer?.cancel();
  _updateTimer = Timer(Duration(milliseconds: 500), () {
    _processPendingUpdates();
    _pendingUpdates.clear();
  });
}
```

### Дотримання ліміту підписок

```dart
// Supabase має ліміт на кількість одночасних підписок
// Відписуйтеся від неактивних каналів

@override
void dispose() {
  // Завжди відписуйтеся при dispose
  _realtimeSubscription?.cancel();
  super.dispose();
}
```

## 7. Debugging

### Логування подій

```dart
realtimeService.subscribeToAllNomenclaturaRelatedChanges()
    .listen((event) {
  print('=== Realtime Event ===');
  print('Type: ${event.type}');
  print('Event: ${event.eventType}');
  print('GUID: ${event.nomGuid}');
  print('New Data: ${event.newData}');
  print('Old Data: ${event.oldData}');
  print('=====================');
});
```

### Перевірка підключення

```dart
final activeSubscriptions = realtimeService.getActiveSubscriptions();
print('Active subscriptions: $activeSubscriptions');

final isSubscribed = realtimeService.isSubscribed('nomenclatura_changes');
print('Subscribed to nomenclatura: $isSubscribed');
```

## 8. Обмеження та рекомендації

### Обмеження

- **Ліміт підписок**: Supabase має ліміт на кількість одночасних realtime підписок
- **Розмір payload**: Великі об'єкти можуть уповільнити передачу
- **Інтернет з'єднання**: Realtime працює тільки при наявності інтернету

### Рекомендації

1. **Завжди відписуйтеся**: Використовуйте `dispose()` або `cancel()`
2. **Селективна підписка**: Підписуйтеся тільки на необхідні дані
3. **Batch оновлення**: Групуйте швидкі оновлення для покращення UI
4. **Fallback**: Мають бути запасні варіанти без realtime
5. **Тестування**: Тестуйте з повільним інтернетом і при відключенні

## 9. Альтернативи

Якщо realtime не працює або не потрібен:

1. **Polling**: Регулярна синхронізація кожні N секунд
2. **Pull-to-refresh**: Ручне оновлення користувачем
3. **Background sync**: Синхронізація при активації додатку
4. **Push notifications**: Сповіщення про зміни через FCM

```dart
// Приклад polling
Timer.periodic(Duration(seconds: 30), (timer) {
  if (mounted && widget.enableAutoRefresh) {
    _refreshData();
  }
});
```

## 10. Тестування імплементації

### Крок 1: Налаштування Supabase

1. Відкрийте Supabase Dashboard -> SQL Editor
2. Виконайте скрипт `supabase_realtime_setup.sql`
3. Переконайтесь що всі команди виконались успішно

### Крок 2: Тестування у Flutter додатку

1. Запустіть додаток: `flutter run`
2. Перейдіть на сторінку "Розширений тест синхронізації"
3. Натисніть "Тест Realtime підключення"
4. Натисніть "Почати підписку"

### Крок 3: Створення тестових змін

Виконайте в Supabase SQL Editor:
```sql
SELECT test_realtime_changes();
```

Ви повинні побачити події в режимі реального часу у Flutter додатку.

### Крок 4: Ручне тестування

Також можете вручну створювати зміни:
```sql
-- Створити новий товар
INSERT INTO nomenklatura (guid, name, article, unit_name, unit_guid, is_folder) 
VALUES ('manual-test-001', 'Ручний тест', 'MT-001', 'шт', '00000000-0000-0000-0000-000000000001', false);

-- Оновити товар
UPDATE nomenklatura SET name = 'Оновлений тест' WHERE guid = 'manual-test-001';

-- Видалити товар
DELETE FROM nomenklatura WHERE guid = 'manual-test-001';
```

### Очікувані результати

- У Flutter додатку повинні з'являтись повідомлення про зміни
- Події логуються з timestamp та деталями
- Підключення показується як активне
- Помилки відображаються в інтерфейсі

### Вирішення проблем

1. **Немає подій**: Перевірте RLS політики та realtime publication
2. **Помилки підключення**: Перевірте URL та ключі Supabase
3. **Події не оновлюються**: Перевірте WebSocket з'єднання

## 11. Файли проекту

- `lib/core/services/realtime_service.dart` - Основний сервіс
- `lib/features/nomenclatura/presentation/pages/realtime_test_page.dart` - Тестова сторінка
- `lib/features/nomenclatura/presentation/widgets/realtime_nomenclatura_list.dart` - Widget зі realtime
- `supabase_realtime_setup.sql` - SQL скрипт налаштування
- `REALTIME_SETUP.md` - Документація (цей файл)

