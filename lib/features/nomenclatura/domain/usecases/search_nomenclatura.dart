import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/nomenclatura.dart';
import '../repositories/nomenclatura_repository.dart';

class SearchNomenclatura {
  final NomenclaturaRepository repository;

  SearchNomenclatura(this.repository);

  Future<Either<Failure, List<Nomenclatura>>> call(String query) async {
    if (query.trim().isEmpty) {
      return const Right([]);
    }

    return await repository.searchNomenclatura(query.trim());
  }
}
