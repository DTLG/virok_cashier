import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/sync_repository.dart';
import '../../../../core/services/data_sync_service.dart';

class CheckSyncStatus {
  final SyncRepository _repository;

  CheckSyncStatus(this._repository);

  Future<Either<Failure, DataSyncInfo>> call() async {
    try {
      final syncInfo = await _repository.checkSyncStatus();
      return Right(syncInfo);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
