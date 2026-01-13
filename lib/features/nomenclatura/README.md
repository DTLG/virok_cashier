# Nomenclatura Feature

Цей модуль реалізує повну функціональність для роботи з номенклатурою через Supabase з локальним кешуванням даних.

## Структура

```
lib/features/nomenclatura/
├── domain/
│   ├── entities/
│   │   └── nomenclatura.dart          # Entity класи (Nomenclatura, Barcode, Price)
│   ├── repositories/
│   │   └── nomenclatura_repository.dart # Repository interface
│   └── usecases/
│       ├── get_all_nomenclatura.dart   # Use case для отримання всієї номенклатури
│       ├── search_nomenclatura.dart    # Use case для пошуку
│       └── sync_nomenclatura.dart      # Use case для синхронізації
├── data/
│   ├── models/
│   │   └── nomenclatura_model.dart     # JSON моделі для serialization
│   ├── datasources/
│   │   ├── nomenclatura_remote_data_source.dart  # Supabase API
│   │   └── nomenclatura_local_data_source.dart   # SQLite кеш
│   └── repositories/
│       └── nomenclatura_repository_impl.dart      # Repository implementation
├── example_usage.dart                  # Приклади використання
└── README.md                          # Ця документація
```

## Основні компоненти

### 1. Entity класи

- **Nomenclatura** - основна сутність номенклатури
- **Barcode** - штрих-код номенклатури
- **Price** - ціна номенклатури

### 2. Repository Pattern

Репозиторій надає єдиний інтерфейс для роботи з даними, автоматично керуючи:
- Отриманням даних з Supabase
- Локальним кешуванням у SQLite
- Офлайн режимом
- Синхронізацією

### 3. Data Sources

- **Remote Data Source** - робота з Supabase API
- **Local Data Source** - робота з локальною SQLite базою даних

## Використання

### Ініціалізація

```dart
import 'package:your_app/core/services/supabase_service.dart';
import 'package:your_app/core/services/nomenclatura_injection.dart';

// Ініціалізуйте Supabase
await SupabaseService.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);

// Ініціалізуйте dependency injection
await initNomenclaturaInjection();
```

### Отримання всієї номенклатури

```dart
final getAllNomenclatura = sl<GetAllNomenclatura>();
final result = await getAllNomenclatura();

result.fold(
  (failure) => print('Помилка: $failure'),
  (nomenclaturas) => print('Отримано ${nomenclaturas.length} номенклатур'),
);
```

### Пошук номенклатури

```dart
final searchNomenclatura = sl<SearchNomenclatura>();
final result = await searchNomenclatura('хліб');

result.fold(
  (failure) => print('Помилка: $failure'),
  (results) => print('Знайдено ${results.length} результатів'),
);
```

### Синхронізація з сервером

```dart
final syncNomenclatura = sl<SyncNomenclatura>();
final result = await syncNomenclatura();

result.fold(
  (failure) => print('Помилка синхронізації: $failure'),
  (_) => print('Синхронізація завершена'),
);
```

### Робота офлайн

```dart
final repository = sl<NomenclaturaRepository>();

// Отримання кешованих даних
final cachedResult = await repository.getCachedNomenclatura();

// Пошук у кеші
final searchResult = await repository.searchCachedNomenclatura('пошуковий запит');
```

## SQL запит для Supabase

Репозиторій виконує JOIN запит як зазначено в вимогах:

```sql
SELECT * 
FROM nomenklatura n
JOIN prices p ON n.guid = p.nom_guid
JOIN barcodes b ON b.nom_guid = n.guid;
```

Це реалізовано через Supabase select з relationships:

```dart
final response = await supabaseClient
    .from('nomenklatura')
    .select('''
      *,
      prices(*),
      barcodes(*)
    ''')
    .order('name');
```

## Структура таблиць Supabase

### Таблиця `nomenklatura`
- `created_at` (timestamptz)
- `name` (varchar)
- `guid` (uuid, primary key)
- `article` (text)
- `unit_name` (text)
- `unit_guid` (uuid)
- `is_folder` (bool)
- `parent_guid` (uuid, nullable)
- `description` (text, nullable)

### Таблиця `barcodes`
- `nom_guid` (uuid, foreign key)
- `barcode` (text)

### Таблиця `prices`
- `created_at` (timestamptz)
- `nom_guid` (uuid, foreign key)
- `price` (float4)

## Функції

✅ **Завершено:**
- Повна CRUD функціональність для номенклатури
- Локальне кешування в SQLite
- Пошук та фільтрація
- Офлайн режим
- Автоматична синхронізація
- JOIN запити з пов'язаними таблицями
- Error handling з типізованими помилками
- Dependency injection
- JSON serialization/deserialization

## Залежності

```yaml
dependencies:
  supabase_flutter: ^2.5.6
  json_annotation: ^4.9.0
  sqflite: ^2.3.3
  path: ^1.9.0
  dartz: # для Either<Failure, Success>
  equatable: # для entity порівнянь
  connectivity: # для перевірки мережі

dev_dependencies:
  json_serializable: ^6.8.0
  build_runner: # для генерації JSON коду
```

## Тестування

Для тестування компонентів використовуйте:
- Mock objects для data sources
- Integration тести для повного flow
- Unit тести для use cases та repository

Приклади тестів можна знайти в папці `test/features/nomenclatura/`.
