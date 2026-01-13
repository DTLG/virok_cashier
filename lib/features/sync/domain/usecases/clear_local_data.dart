import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/sync_repository.dart';

class ClearLocalData {
  final SyncRepository _repository;

  ClearLocalData(this._repository);

  Future<Either<Failure, void>> call() async {
    try {
      final result = await _repository.clearAllLocalData();
      return result;
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
