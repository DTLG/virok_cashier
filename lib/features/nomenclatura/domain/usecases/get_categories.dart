import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/nomenclatura.dart';
import '../repositories/nomenclatura_repository.dart';

class GetCategories {
  final NomenclaturaRepository repository;

  GetCategories(this.repository);

  Future<Either<Failure, List<Nomenclatura>>> call() async {
    return await repository.getCachedCategories();
  }
}
