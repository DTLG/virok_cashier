import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/nomenclatura_repository.dart';

class SyncNomenclatura {
  final NomenclaturaRepository repository;

  SyncNomenclatura(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.syncWithServer();
  }
}
