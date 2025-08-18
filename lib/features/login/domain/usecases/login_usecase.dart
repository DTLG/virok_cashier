import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_data.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase({required this.repository});

  Future<Either<Failure, UserData>> call(String email, String password) async {
    // Додаємо валідацію email формату
    if (!_isValidEmail(email)) {
      return Left(ServerFailure('Невірний формат email'));
    }

    return await repository.login(email, password);
  }

  bool _isValidEmail(String email) {
    // Проста валідація email формату
    // final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    // return emailRegex.hasMatch(email);
    return true;
  }
}
