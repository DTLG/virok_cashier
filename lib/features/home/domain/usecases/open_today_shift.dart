import '../repositories/home_repository.dart';

class OpenTodayShift {
  final HomeRepository repository;
  OpenTodayShift(this.repository);
  Future<void> call() => repository.openTodayShift();
}
