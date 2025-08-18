import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_data.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserData>> login(String email, String password);
}
