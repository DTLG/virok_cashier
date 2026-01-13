import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/sync_repository.dart';

class PerformSync {
  final SyncRepository _repository;

  PerformSync(this._repository);

  Future<Either<Failure, void>> call({
    bool forceSync = false,
    void Function(String message, double progress)? onProgress,
  }) async {
    try {
      if (forceSync) {
        final result = await _repository.forceSyncAllData(
          onProgress: onProgress,
        );
        return result;
      } else {
        final result = await _repository.syncAllData(onProgress: onProgress);
        return result;
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
