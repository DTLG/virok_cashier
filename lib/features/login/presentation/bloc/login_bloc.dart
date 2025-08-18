import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/usecases/login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final StorageService storageService;

  LoginBloc({required this.loginUseCase, required this.storageService})
    : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    final result = await loginUseCase(event.email, event.password);
    await result.fold(
      (failure) async {
        emit(
          LoginFailure(
            failure is ServerFailure ? failure.message : failure.toString(),
          ),
        );
      },
      (user) async {
        // Зберігаємо дані користувача в SharedPreferences
        await storageService.saveUserCredentials(event.email, event.password);
        emit(LoginSuccess(user));
      },
    );
  }
}
