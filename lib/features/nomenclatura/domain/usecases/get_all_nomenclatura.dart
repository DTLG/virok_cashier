import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/nomenclatura.dart';
import '../repositories/nomenclatura_repository.dart';

class GetAllNomenclatura {
  final NomenclaturaRepository repository;

  GetAllNomenclatura(this.repository);

  Future<Either<Failure, List<Nomenclatura>>> call({
    void Function(String message, double progress)? onProgress,
    bool includeRelations = true,
  }) async {
    return await repository.getAllNomenclatura(
      onProgress: onProgress,
      includeRelations: includeRelations,
    );
  }
}
