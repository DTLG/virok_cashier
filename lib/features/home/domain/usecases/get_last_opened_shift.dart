import '../repositories/home_repository.dart';

class GetLastOpenedShift {
  final HomeRepository repository;
  GetLastOpenedShift(this.repository);
  Future<DateTime?> call() => repository.getLastOpenedShift();
}
