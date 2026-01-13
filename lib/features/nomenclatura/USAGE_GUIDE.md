# Керівництво з використання Nomenclatura Feature

## Покрокова інструкція

### 1. Налаштування Supabase

```dart
// В main.dart або в функції ініціалізації додатку
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key',
);
```

### 2. Реєстрація dependencies

```dart
// В main.dart або service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:connectivity/connectivity.dart';
import 'features/nomenclatura/data/datasources/nomenclatura_remote_data_source.dart';
import 'features/nomenclatura/data/datasources/nomenclatura_local_data_source.dart';
import 'features/nomenclatura/data/repositories/nomenclatura_repository_impl.dart';
import 'features/nomenclatura/domain/repositories/nomenclatura_repository.dart';
import 'features/nomenclatura/domain/usecases/get_all_nomenclatura.dart';
import 'features/nomenclatura/domain/usecases/search_nomenclatura.dart';
import 'features/nomenclatura/domain/usecases/sync_nomenclatura.dart';

final sl = GetIt.instance;

void setupNomenclaturaInjection() {
  // Data sources
  sl.registerLazySingleton<NomenclaturaRemoteDataSource>(
    () => NomenclaturaRemoteDataSourceImpl(
      supabaseClient: Supabase.instance.client,
    ),
  );

  sl.registerLazySingleton<NomenclaturaLocalDataSource>(
    () => NomenclaturaLocalDataSourceImpl(),
  );

  // Repository
  sl.registerLazySingleton<NomenclaturaRepository>(
    () => NomenclaturaRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllNomenclatura(sl()));
  sl.registerLazySingleton(() => SearchNomenclatura(sl()));
  sl.registerLazySingleton(() => SyncNomenclatura(sl()));

  // External
  sl.registerLazySingleton(() => Connectivity());
}
```

### 3. Використання в коді

#### Отримання всієї номенклатури

```dart
final getAllNomenclatura = sl<GetAllNomenclatura>();
final result = await getAllNomenclatura();

result.fold(
  (failure) {
    // Обробка помилки
    print('Помилка: ${failure.message}');
  },
  (nomenclaturas) {
    // Успішне отримання даних
    print('Отримано ${nomenclaturas.length} номенклатур');
    for (final item in nomenclaturas) {
      print('${item.name} - ${item.article}');
    }
  },
);
```

#### Пошук номенклатури

```dart
final searchNomenclatura = sl<SearchNomenclatura>();
final result = await searchNomenclatura('хліб');

result.fold(
  (failure) => showError(failure.message),
  (results) => displayResults(results),
);
```

#### Синхронізація з сервером

```dart
final syncNomenclatura = sl<SyncNomenclatura>();
final result = await syncNomenclatura();

result.fold(
  (failure) => showSyncError(failure.message),
  (_) => showSyncSuccess(),
);
```

### 4. Приклад використання у Widget

```dart
class NomenclaturaPage extends StatefulWidget {
  @override
  _NomenclaturaPageState createState() => _NomenclaturaPageState();
}

class _NomenclaturaPageState extends State<NomenclaturaPage> {
  List<Nomenclatura> _nomenclaturas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNomenclatura();
  }

  Future<void> _loadNomenclatura() async {
    setState(() => _isLoading = true);
    
    final getAllNomenclatura = sl<GetAllNomenclatura>();
    final result = await getAllNomenclatura();
    
    setState(() {
      _isLoading = false;
      result.fold(
        (failure) {
          // Показати помилку
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка: ${failure.message}')),
          );
        },
        (nomenclaturas) => _nomenclaturas = nomenclaturas,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Номенклатура')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _nomenclaturas.length,
              itemBuilder: (context, index) {
                final item = _nomenclaturas[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.article),
                  trailing: Text('${item.prices.isNotEmpty ? item.prices.first.price : 0} грн'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNomenclatura,
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

### 5. Офлайн режим

```dart
// Для роботи офлайн використовуйте repository напряму
final repository = sl<NomenclaturaRepository>();

// Отримання кешованих даних
final cachedResult = await repository.getCachedNomenclatura();

// Пошук у кеші
final searchResult = await repository.searchCachedNomenclatura('запит');

// Час останньої синхронізації
final lastSyncResult = await repository.getLastSyncTime();
```

### 6. Обробка помилок

```dart
result.fold(
  (failure) {
    if (failure is NetworkFailure) {
      // Немає інтернету
      print('Перевірте підключення до інтернету');
    } else if (failure is ServerFailure) {
      // Помилка сервера
      print('Помилка сервера: ${failure.message}');
    } else if (failure is CacheFailure) {
      // Помилка кешу
      print('Помилка локального сховища: ${failure.message}');
    }
  },
  (data) {
    // Успішний результат
    print('Дані отримано успішно');
  },
);
```

## Структура SQL таблиць для Supabase

### nomenklatura
```sql
CREATE TABLE nomenklatura (
    created_at TIMESTAMPTZ DEFAULT NOW(),
    name VARCHAR NOT NULL,
    guid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article TEXT NOT NULL,
    unit_name TEXT NOT NULL,
    unit_guid UUID NOT NULL,
    is_folder BOOLEAN DEFAULT FALSE,
    parent_guid UUID REFERENCES nomenklatura(guid),
    description TEXT
);
```

### barcodes
```sql
CREATE TABLE barcodes (
    nom_guid UUID REFERENCES nomenklatura(guid) ON DELETE CASCADE,
    barcode TEXT NOT NULL
);
```

### prices
```sql
CREATE TABLE prices (
    created_at TIMESTAMPTZ DEFAULT NOW(),
    nom_guid UUID REFERENCES nomenklatura(guid) ON DELETE CASCADE,
    price FLOAT4 NOT NULL
);
```

## Важливі зауваження

1. **Автоматичне кешування**: Репозиторій автоматично кешує дані при кожному успішному запиті.

2. **Офлайн режим**: Якщо немає інтернету, репозиторій автоматично повертає кешовані дані.

3. **JOIN запити**: Система автоматично виконує JOIN запити для отримання пов'язаних даних (barcodes та prices).

4. **Типізовані помилки**: Всі помилки типізовані і можна легко обробити різні сценарії.

5. **Clean Architecture**: Код організований за принципами Clean Architecture з чіткою сепарацією шарів.
