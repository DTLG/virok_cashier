import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/sync_repository.dart';

class GetDetailedSyncInfo {
  final SyncRepository _repository;

  GetDetailedSyncInfo(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call() async {
    try {
      final result = await _repository.getDetailedSyncInfo();
      return result;
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
