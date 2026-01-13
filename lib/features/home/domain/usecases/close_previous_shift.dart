import '../repositories/home_repository.dart';

class ClosePreviousShift {
  final HomeRepository repository;
  ClosePreviousShift(this.repository);
  Future<void> call() => repository.closePreviousShift();
}
