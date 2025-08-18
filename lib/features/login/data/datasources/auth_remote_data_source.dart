import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email == 'admin' && password == 'admin') {
      return const UserModel(
        id: '1',
        name: 'Адміністратор',
        email: 'admin',
        password: 'admin',
      );
    } else {
      throw Exception('Невірні облікові дані');
    }
  }
}
