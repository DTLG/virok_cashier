import '../repositories/home_repository.dart';

class CheckUserLoginStatus {
  final HomeRepository repository;
  CheckUserLoginStatus(this.repository);
  Future<bool> call() => repository.isUserLoggedIn();
}
