import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/nomenclatura.dart';
import '../../domain/repositories/nomenclatura_repository.dart';
import '../datasources/nomenclatura_remote_data_source.dart';
import '../datasources/nomenclatura_local_data_source.dart';
import '../models/nomenclatura_model.dart';

class NomenclaturaRepositoryImpl implements NomenclaturaRepository {
  final NomenclaturaRemoteDataSource remoteDataSource;
  final NomenclaturaLocalDataSource localDataSource;
  final Connectivity connectivity;

  NomenclaturaRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivity,
  });

  @override
  Future<Either<Failure, List<Nomenclatura>>> getAllNomenclatura({
    void Function(String message, double progress)? onProgress,
    bool includeRelations = true,
  }) async {
    try {
      // final connectivityResult = await connectivity.checkConnectivity();

      // if (connectivityResult == ConnectivityResult.none) {
      //   // Якщо немає інтернету, повертаємо кешовані дані
      //   return await getCachedNomenclatura();
      // }

      // Отримуємо дані з сервера
      final remoteNomenclatura = await remoteDataSource.getAllNomenclatura(
        onProgress: onProgress,
        includeRelations: includeRelations,
      );

      // Кешуємо отримані дані
      await localDataSource.cacheNomenclatura(remoteNomenclatura);
      await localDataSource.cacheLastSync(DateTime.now());

      return Right(
        remoteNomenclatura.map((model) => model.toEntity()).toList(),
      );
    } on ServerFailure catch (failure) {
      // Якщо помилка сервера, спробуємо повернути кешовані дані
      final cachedResult = await getCachedNomenclatura();
      return cachedResult.fold(
        (l) => Left(
          failure,
        ), // Якщо і кеш не працює, повертаємо оригінальну помилку
        (r) => Right(r), // Повертаємо кешовані дані
      );
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Nomenclatura?>> getNomenclaturaByGuid(
    String guid,
  ) async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        // Якщо немає інтернету, шукаємо в кеші
        final cached = await localDataSource.getCachedNomenclaturaByGuid(guid);
        return Right(cached?.toEntity());
      }

      // Спочатку намагаємося отримати з сервера
      final remote = await remoteDataSource.getNomenclaturaByGuid(guid);

      if (remote != null) {
        // Кешуємо отриманий об'єкт
        await localDataSource.cacheNomenclatura([remote]);
        return Right(remote.toEntity());
      } else {
        // Якщо не знайдено на сервері, шукаємо в кеші
        final cached = await localDataSource.getCachedNomenclaturaByGuid(guid);
        return Right(cached?.toEntity());
      }
    } on ServerFailure catch (failure) {
      // При помилці сервера, шукаємо в кеші
      try {
        final cached = await localDataSource.getCachedNomenclaturaByGuid(guid);
        return Right(cached?.toEntity());
      } catch (e) {
        return Left(failure);
      }
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Nomenclatura>>> searchNomenclatura(
    String query,
  ) async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        // Якщо немає інтернету, шукаємо в кеші
        return await searchCachedNomenclatura(query);
      }

      // Пошук на сервері
      final remoteResults = await remoteDataSource.searchNomenclatura(query);

      // Кешуємо результати пошуку
      if (remoteResults.isNotEmpty) {
        await localDataSource.cacheNomenclatura(remoteResults);
      }

      return Right(remoteResults.map((model) => model.toEntity()).toList());
    } on ServerFailure catch (failure) {
      // При помилці сервера, шукаємо в кеші
      final cachedResult = await searchCachedNomenclatura(query);
      return cachedResult.fold((l) => Left(failure), (r) => Right(r));
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Nomenclatura>>> getCachedNomenclatura() async {
    try {
      final cached = await localDataSource.getCachedNomenclatura();
      return Right(cached.map((model) => model.toEntity()).toList());
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(CacheFailure('Unexpected cache error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Nomenclatura>>> searchCachedNomenclatura(
    String query,
  ) async {
    try {
      final cached = await localDataSource.searchCachedNomenclatura(query);
      return Right(cached.map((model) => model.toEntity()).toList());
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(CacheFailure('Unexpected cache error: $e'));
    }
  }

  @override
  Future<Either<Failure, Nomenclatura>> createNomenclatura(
    Nomenclatura nomenclatura,
  ) async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      final nomenclaturaModel = _nomenclaturaToModel(nomenclatura);
      final created = await remoteDataSource.createNomenclatura(
        nomenclaturaModel,
      );

      // Кешуємо створений об'єкт
      await localDataSource.cacheNomenclatura([created]);

      return Right(created.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Nomenclatura>> updateNomenclatura(
    Nomenclatura nomenclatura,
  ) async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      final nomenclaturaModel = _nomenclaturaToModel(nomenclatura);
      final updated = await remoteDataSource.updateNomenclatura(
        nomenclaturaModel,
      );

      // Оновлюємо кеш
      final allCached = await localDataSource.getCachedNomenclatura();
      final updatedList = allCached
          .where((item) => item.guid != updated.guid)
          .toList();
      updatedList.add(updated);
      await localDataSource.cacheNomenclatura(updatedList);

      return Right(updated.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNomenclatura(String guid) async {
    try {
      final connectivityResult = await connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return Left(NetworkFailure('No internet connection'));
      }

      await remoteDataSource.deleteNomenclatura(guid);

      // Видаляємо з кешу - оновлюємо весь кеш без цього елемента
      final allCached = await localDataSource.getCachedNomenclatura();
      final filteredList = allCached
          .where((item) => item.guid != guid)
          .toList();
      await localDataSource.cacheNomenclatura(filteredList);

      return const Right(null);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncWithServer() async {
    try {
      // Спочатку спробуємо виконати запит без перевірки connectivity
      print('Starting sync with server...'); // Debug log

      final remoteNomenclatura = await remoteDataSource.getAllNomenclatura();
      print(
        'Successfully fetched ${remoteNomenclatura.length} items from server',
      ); // Debug log

      await localDataSource.cacheNomenclatura(remoteNomenclatura);
      await localDataSource.cacheLastSync(DateTime.now());

      print('Successfully cached data and sync time'); // Debug log
      return const Right(null);
    } on ServerFailure catch (failure) {
      print('Server failure during sync: $failure'); // Debug log
      return Left(failure);
    } on CacheFailure catch (failure) {
      print('Cache failure during sync: $failure'); // Debug log
      return Left(failure);
    } catch (e) {
      print('Unexpected error during sync: $e'); // Debug log

      // Перевіряємо connectivity тільки після невдачі
      try {
        final connectivityResult = await connectivity.checkConnectivity();
        print(
          'Connectivity result after error: $connectivityResult',
        ); // Debug log
        if (connectivityResult == ConnectivityResult.none) {
          return Left(NetworkFailure('No internet connection'));
        }
      } catch (connectivityError) {
        print('Connectivity check failed: $connectivityError'); // Debug log
      }

      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  /// Примусова синхронізація з повним очищенням кешу
  Future<Either<Failure, void>> forceSyncWithServer() async {
    try {
      print('Starting FORCE sync with server...'); // Debug log

      final remoteNomenclatura = await remoteDataSource.getAllNomenclatura(
        includeRelations: false, // Швидка синхронізація для початку
      );
      print(
        'Successfully fetched ${remoteNomenclatura.length} items from server (force sync)',
      ); // Debug log

      // Використовуємо примусове кешування з очищенням
      await localDataSource.forceCacheNomenclatura(remoteNomenclatura);
      await localDataSource.cacheLastSync(DateTime.now());

      print('Successfully force cached data and sync time'); // Debug log
      return const Right(null);
    } on ServerFailure catch (failure) {
      print('Server failure during force sync: $failure'); // Debug log
      return Left(failure);
    } on CacheFailure catch (failure) {
      print('Cache failure during force sync: $failure'); // Debug log
      return Left(failure);
    } catch (e) {
      print('Unexpected error during force sync: $e'); // Debug log
      return Left(ServerFailure('Unexpected error during force sync: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await localDataSource.clearCache();
      return const Right(null);
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(CacheFailure('Unexpected cache error: $e'));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncTime() async {
    try {
      final lastSync = await localDataSource.getLastSync();
      return Right(lastSync);
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(CacheFailure('Unexpected cache error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Nomenclatura>>> getCachedCategories() async {
    try {
      final cachedCategories = await localDataSource.getCachedCategories();
      return Right(cachedCategories.map((model) => model.toEntity()).toList());
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(CacheFailure('Unexpected error getting categories: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Nomenclatura>>> getCachedSubcategories(
    String parentGuid,
  ) async {
    try {
      final cachedSubcategories = await localDataSource.getCachedSubcategories(
        parentGuid,
      );
      return Right(
        cachedSubcategories.map((model) => model.toEntity()).toList(),
      );
    } on CacheFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(CacheFailure('Unexpected error getting subcategories: $e'));
    }
  }

  // Приватний метод для конвертації entity в model
  NomenclaturaModel _nomenclaturaToModel(Nomenclatura nomenclatura) {
    return NomenclaturaModel.fromEntity(nomenclatura);
  }
}
