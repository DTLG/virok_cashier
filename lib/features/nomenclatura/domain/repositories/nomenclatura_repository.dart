import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/nomenclatura.dart';

abstract class NomenclaturaRepository {
  /// Отримує всю номенклатуру з сервера та кешує локально
  Future<Either<Failure, List<Nomenclatura>>> getAllNomenclatura({
    void Function(String message, double progress)? onProgress,
    bool includeRelations = true,
  });

  /// Отримує номенклатуру за GUID
  Future<Either<Failure, Nomenclatura?>> getNomenclaturaByGuid(String guid);

  /// Пошук номенклатури за запитом
  Future<Either<Failure, List<Nomenclatura>>> searchNomenclatura(String query);

  /// Отримує кешовану номенклатуру (offline)
  Future<Either<Failure, List<Nomenclatura>>> getCachedNomenclatura();

  /// Пошук в кешованій номенклатурі (offline)
  Future<Either<Failure, List<Nomenclatura>>> searchCachedNomenclatura(
    String query,
  );

  /// Отримує кореневі категорії (записи з isFolder = true і parent_guid = null) з локального кешу
  Future<Either<Failure, List<Nomenclatura>>> getCachedCategories();

  /// Отримує підкатегорії та товари для заданої категорії (parent_guid)
  Future<Either<Failure, List<Nomenclatura>>> getCachedSubcategories(
    String parentGuid,
  );

  /// Створює нову номенклатуру
  Future<Either<Failure, Nomenclatura>> createNomenclatura(
    Nomenclatura nomenclatura,
  );

  /// Оновлює існуючу номенклатуру
  Future<Either<Failure, Nomenclatura>> updateNomenclatura(
    Nomenclatura nomenclatura,
  );

  /// Видаляє номенклатуру
  Future<Either<Failure, void>> deleteNomenclatura(String guid);

  /// Синхронізує дані з сервером
  Future<Either<Failure, void>> syncWithServer();

  /// Очищає локальний кеш
  Future<Either<Failure, void>> clearCache();

  /// Отримує час останньої синхронізації
  Future<Either<Failure, DateTime?>> getLastSyncTime();
}
