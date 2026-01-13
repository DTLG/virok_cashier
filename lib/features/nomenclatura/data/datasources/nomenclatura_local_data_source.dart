import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/nomenclatura_model.dart';
import '../../../../core/error/failures.dart';

abstract class NomenclaturaLocalDataSource {
  Future<void> cacheNomenclatura(List<NomenclaturaModel> nomenclaturas);
  Future<void> forceCacheNomenclatura(List<NomenclaturaModel> nomenclaturas);
  Future<List<NomenclaturaModel>> getCachedNomenclatura();
  Future<NomenclaturaModel?> getCachedNomenclaturaByGuid(String guid);
  Future<List<NomenclaturaModel>> searchCachedNomenclatura(String query);

  /// Отримує кореневі категорії (isFolder = true і parent_guid = null)
  Future<List<NomenclaturaModel>> getCachedCategories();

  /// Отримує підкатегорії та товари за parent_guid
  Future<List<NomenclaturaModel>> getCachedSubcategories(String parentGuid);
  Future<void> clearCache();
  Future<void> cacheLastSync(DateTime lastSync);
  Future<DateTime?> getLastSync();
}

class NomenclaturaLocalDataSourceImpl implements NomenclaturaLocalDataSource {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'nomenclatura.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Створюємо таблицю номенклатури
    await db.execute('''
      CREATE TABLE nomenclatura (
        guid TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        name TEXT NOT NULL,
        article TEXT NOT NULL,
        unit_name TEXT NOT NULL,
        unit_guid TEXT NOT NULL,
        is_folder INTEGER NOT NULL,
        parent_guid TEXT,
        description TEXT,
        barcodes TEXT,
        price REAL,
        search_name TEXT
      )
    ''');

    // Створюємо таблицю для збереження часу останньої синхронізації
    await db.execute('''
      CREATE TABLE sync_info (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Створюємо індекси для оптимізації пошуку
    await db.execute(
      'CREATE INDEX idx_nomenclatura_name ON nomenclatura (name)',
    );
    await db.execute(
      'CREATE INDEX idx_nomenclatura_search_name ON nomenclatura (search_name)',
    );
    await db.execute(
      'CREATE INDEX idx_nomenclatura_article ON nomenclatura (article)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Додаємо нові колонки для зберігання баркодів та ціни без окремих таблиць
      await db.execute('ALTER TABLE nomenclatura ADD COLUMN barcodes TEXT');
      await db.execute('ALTER TABLE nomenclatura ADD COLUMN price REAL');
      // Видаляємо зайві таблиці, якщо існують
      await db.execute('DROP TABLE IF EXISTS barcodes');
      await db.execute('DROP TABLE IF EXISTS prices');
    }

    if (oldVersion < 3) {
      // Додаємо колонку search_name та оновлюємо її для існуючих записів
      await db.execute('ALTER TABLE nomenclatura ADD COLUMN search_name TEXT');

      // Створюємо індекс для search_name
      await db.execute(
        'CREATE INDEX idx_nomenclatura_search_name ON nomenclatura (search_name)',
      );

      // Оновлюємо search_name для всіх існуючих записів
      await db.execute('''
        UPDATE nomenclatura 
        SET search_name = LOWER(article || name)
        WHERE search_name IS NULL OR search_name = ''
      ''');
    }
  }

  @override
  Future<void> cacheNomenclatura(List<NomenclaturaModel> nomenclaturas) async {
    await _cacheNomenclaturaWithStrategy(nomenclaturas, clearFirst: false);
  }

  /// Кешує номенклатуру з можливістю очищення
  Future<void> _cacheNomenclaturaWithStrategy(
    List<NomenclaturaModel> nomenclaturas, {
    bool clearFirst = false,
  }) async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        if (clearFirst) {
          // Повне очищення перед вставкою (для примусової синхронізації)
          print('Clearing all cached data...'); // Debug log

          // Видаляємо з більш детальними логами
          // final barcodesDeleted = await txn.delete('barcodes');
          // print('Deleted $barcodesDeleted barcodes');

          // final pricesDeleted = await txn.delete('prices');
          // print('Deleted $pricesDeleted prices');

          final nomenclaturaDeleted = await txn.delete('nomenclatura');
          print('Deleted $nomenclaturaDeleted nomenclatura items');

          // Перевіряємо чи дійсно все видалено
          final remainingNomenclatura = await txn.rawQuery(
            'SELECT COUNT(*) as count FROM nomenclatura',
          );
          final remainingCount = remainingNomenclatura.first['count'] as int;
          if (remainingCount > 0) {
            print(
              'WARNING: $remainingCount nomenclatura items still remain after deletion!',
            );
            // Примусово видаляємо
            await txn.execute('DELETE FROM nomenclatura');
            print('Force deleted all nomenclatura items');
          }

          print('All cached data cleared'); // Debug log
        }

        print(
          'Caching ${nomenclaturas.length} nomenclatura items...',
        ); // Debug log

        // Перевіряємо на дублікати GUID
        final guidSet = <String>{};
        final duplicateGuids = <String>[];
        for (final nomenclatura in nomenclaturas) {
          if (guidSet.contains(nomenclatura.guid)) {
            duplicateGuids.add(nomenclatura.guid);
          } else {
            guidSet.add(nomenclatura.guid);
          }
        }

        if (duplicateGuids.isNotEmpty) {
          print(
            'WARNING: Found ${duplicateGuids.length} duplicate GUIDs in data: ${duplicateGuids.take(5).join(', ')}${duplicateGuids.length > 5 ? '...' : ''}',
          );
        }

        // Вставляємо дані пакетами для кращої продуктивності
        for (int i = 0; i < nomenclaturas.length; i += 100) {
          final batch = nomenclaturas.skip(i).take(100).toList();

          for (final nomenclatura in batch) {
            // Завжди використовуємо INSERT OR REPLACE для уникнення конфліктів
            await txn.execute(
              '''
                INSERT OR REPLACE INTO nomenclatura 
                (guid, created_at, name, article, unit_name, unit_guid, is_folder, parent_guid, description, barcodes, price, search_name) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
               ''',
              [
                nomenclatura.guid,
                nomenclatura.createdAt.toIso8601String(),
                nomenclatura.name,
                nomenclatura.article,
                nomenclatura.unitName,
                nomenclatura.unitGuid,
                nomenclatura.isFolder ? 1 : 0,
                nomenclatura.parentGuid,
                nomenclatura.description,
                nomenclatura.barcodes,
                nomenclatura.prices,
                nomenclatura.searchName,
              ],
            );
          }

          // Показуємо прогрес кешування
          if (i + 100 < nomenclaturas.length) {
            print(
              'Cached ${i + 100}/${nomenclaturas.length} items...',
            ); // Debug log
          }
        }

        print(
          'Successfully cached ${nomenclaturas.length} nomenclatura items',
        ); // Debug log
      });
    } catch (e) {
      print('Error caching nomenclatura: $e'); // Debug log
      throw CacheFailure('Failed to cache nomenclatura: $e');
    }
  }

  /// Метод для примусової синхронізації з повним очищенням
  Future<void> forceCacheNomenclatura(
    List<NomenclaturaModel> nomenclaturas,
  ) async {
    await _cacheNomenclaturaWithStrategy(nomenclaturas, clearFirst: true);
  }

  @override
  Future<List<NomenclaturaModel>> getCachedNomenclatura() async {
    final db = await database;

    try {
      final nomenclaturaRows = await db.query('nomenclatura', orderBy: 'name');

      if (nomenclaturaRows.isEmpty) {
        return [];
      }

      final List<NomenclaturaModel> result = [];

      for (final row in nomenclaturaRows) {
        final nomenclatura = NomenclaturaModel(
          guid: row['guid'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          name: row['name'] as String,
          article: row['article'] as String,
          unitName: row['unit_name'] as String,
          unitGuid: row['unit_guid'] as String,
          isFolder: (row['is_folder'] as int) == 1,
          parentGuid: row['parent_guid'] as String?,
          description: row['description'] as String?,
          barcodes: (row['barcodes'] as String?) ?? '',
          prices: (row['price'] as num?)?.toDouble() ?? 0.0,
          searchName: (row['search_name'] as String?) ?? '',
        );

        result.add(nomenclatura);
      }

      return result;
    } catch (e) {
      throw CacheFailure('Failed to get cached nomenclatura: $e');
    }
  }

  @override
  Future<NomenclaturaModel?> getCachedNomenclaturaByGuid(String guid) async {
    final db = await database;

    try {
      final rows = await db.query(
        'nomenclatura',
        where: 'guid = ?',
        whereArgs: [guid],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      final row = rows.first;

      return NomenclaturaModel(
        guid: guid,
        createdAt: DateTime.parse(row['created_at'] as String),
        name: row['name'] as String,
        article: row['article'] as String,
        unitName: row['unit_name'] as String,
        unitGuid: row['unit_guid'] as String,
        isFolder: (row['is_folder'] as int) == 1,
        parentGuid: row['parent_guid'] as String?,
        description: row['description'] as String?,
        barcodes: (row['barcodes'] as String?) ?? '',
        prices: (row['price'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      throw CacheFailure('Failed to get cached nomenclatura by guid: $e');
    }
  }

  @override
  Future<List<NomenclaturaModel>> searchCachedNomenclatura(String query) async {
    final db = await database;

    try {
      // Пошук по полю search_name (найшвидший) + додаткові поля для повноти
      final nomenclaturaRows = await db.query(
        'nomenclatura',
        where: 'search_name LIKE ? AND is_folder = ?',
        whereArgs: ['%$query%', 0],
        orderBy: 'name',
        limit: 100,
      );

      if (nomenclaturaRows.isEmpty) {
        return [];
      }

      final List<NomenclaturaModel> result = [];

      for (final row in nomenclaturaRows) {
        final nomenclatura = NomenclaturaModel(
          guid: row['guid'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          name: row['name'] as String,
          article: row['article'] as String,
          unitName: row['unit_name'] as String,
          unitGuid: row['unit_guid'] as String,
          isFolder: (row['is_folder'] as int) == 1,
          parentGuid: row['parent_guid'] as String?,
          description: row['description'] as String?,
          barcodes: (row['barcodes'] as String?) ?? '',
          prices: (row['price'] as num?)?.toDouble() ?? 0.0,
          searchName: (row['search_name'] as String?) ?? '',
        );

        result.add(nomenclatura);
      }

      return result;
    } catch (e) {
      throw CacheFailure('Failed to search cached nomenclatura: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        // await txn.delete('barcodes');
        // await txn.delete('prices');
        await txn.delete('nomenclatura');
      });
    } catch (e) {
      throw CacheFailure('Failed to clear cache: $e');
    }
  }

  @override
  Future<void> cacheLastSync(DateTime lastSync) async {
    final db = await database;

    try {
      await db.insert('sync_info', {
        'key': 'last_sync',
        'value': lastSync.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw CacheFailure('Failed to cache last sync: $e');
    }
  }

  @override
  Future<DateTime?> getLastSync() async {
    final db = await database;

    try {
      final rows = await db.query(
        'sync_info',
        where: 'key = ?',
        whereArgs: ['last_sync'],
        limit: 1,
      );

      if (rows.isEmpty) {
        return null;
      }

      return DateTime.parse(rows.first['value'] as String);
    } catch (e) {
      throw CacheFailure('Failed to get last sync: $e');
    }
  }

  @override
  Future<List<NomenclaturaModel>> getCachedCategories() async {
    final db = await database;

    try {
      print(
        'Fetching root categories from cache (isFolder = 1 AND parent_guid IS NULL)...',
      );

      final result = await db.rawQuery('''
        SELECT 
          n.guid, n.created_at, n.name, n.article, n.unit_name, n.unit_guid, 
          n.is_folder, n.parent_guid, n.description, n.barcodes, n.price
        FROM nomenclatura n
        WHERE n.is_folder = 1 AND (n.parent_guid IS NULL OR n.parent_guid = '00000000-0000-0000-0000-000000000000')
        ORDER BY n.name ASC
      ''');

      print('Found ${result.length} root categories in cache');

      if (result.isEmpty) return [];

      return result.map((row) {
        return NomenclaturaModel(
          guid: row['guid'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          name: row['name'] as String,
          article: row['article'] as String,
          unitName: row['unit_name'] as String,
          unitGuid: row['unit_guid'] as String,
          isFolder: (row['is_folder'] as int) == 1,
          parentGuid: row['parent_guid'] as String?,
          description: row['description'] as String?,
          barcodes: (row['barcodes'] as String?) ?? '',
          prices: (row['price'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      print('Error fetching cached categories: $e');
      throw CacheFailure('Failed to get cached categories: $e');
    }
  }

  @override
  Future<List<NomenclaturaModel>> getCachedSubcategories(
    String parentGuid,
  ) async {
    final db = await database;

    try {
      print('Fetching subcategories for parent_guid: $parentGuid...');

      final result = await db.rawQuery(
        '''
        SELECT 
          n.guid, n.created_at, n.name, n.article, n.unit_name, n.unit_guid, 
          n.is_folder, n.parent_guid, n.description, n.barcodes, n.price
        FROM nomenclatura n
        WHERE n.parent_guid = ?
        ORDER BY n.is_folder DESC, n.name ASC
      ''',
        [parentGuid],
      );

      print('Found ${result.length} items for parent_guid: $parentGuid');

      if (result.isEmpty) return [];

      return result.map((row) {
        return NomenclaturaModel(
          guid: row['guid'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          name: row['name'] as String,
          article: row['article'] as String,
          unitName: row['unit_name'] as String,
          unitGuid: row['unit_guid'] as String,
          isFolder: (row['is_folder'] as int) == 1,
          parentGuid: row['parent_guid'] as String?,
          description: row['description'] as String?,
          barcodes: (row['barcodes'] as String?) ?? '',
          prices: (row['price'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      print('Error fetching cached subcategories: $e');
      throw CacheFailure('Failed to get cached subcategories: $e');
    }
  }

  // Допоміжні таблиці більше не потрібні
}
