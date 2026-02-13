import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_state.dart';
import '../widgets/login_form.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/storage/storage_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        storageService: StorageService(),
        loginUseCase: LoginUseCase(
          repository: AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
          ),
        ),
      ),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.of(context).pushReplacementNamed(AppRouter.home);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          body: Row(
            children: [
              // Ліва панель з логотипом
              Container(
                width: 400,
                color: const Color(0xFF2A2A2A),
                child: Column(
                  children: [
                    // Логотип Virok
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.home_repair_service_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Virok',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Підзаголовок
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: const Text(
                        'Каса',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),

                    const Spacer(),

                    // Копірайт
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: const Text(
                        '© 2025 Virok App',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Права панель з формою логіну
              Expanded(
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Заголовок
                          const Text(
                            'Вхід в систему',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Введіть ваші облікові дані для доступу',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 40),

                          // Форма логіну
                          const LoginForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
