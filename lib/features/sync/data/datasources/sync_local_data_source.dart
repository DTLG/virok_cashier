import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Інтерфейс локального джерела даних для синхронізації
abstract class SyncLocalDataSource {
  Future<Either<Failure, void>> clearAllLocalData();
}

class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  final Future<Either<Failure, void>> Function() clearAll;

  SyncLocalDataSourceImpl({required this.clearAll});

  @override
  Future<Either<Failure, void>> clearAllLocalData() => clearAll();
}
