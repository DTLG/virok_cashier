import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/nomenclatura.dart';
import '../repositories/nomenclatura_repository.dart';

class GetSubcategories {
  final NomenclaturaRepository repository;

  GetSubcategories(this.repository);

  Future<Either<Failure, List<Nomenclatura>>> call(String parentGuid) async {
    return await repository.getCachedSubcategories(parentGuid);
  }
}
