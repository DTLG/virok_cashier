import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/storage_service.dart';
import '../../../login/domain/entities/user_data.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final StorageService storageService;

  HomeBloc({required this.storageService}) : super(HomeInitial()) {
    on<CheckUserLoginStatus>(_onCheckUserLoginStatus);
    on<LogoutUser>(_onLogoutUser);
  }

  Future<void> _onCheckUserLoginStatus(
    CheckUserLoginStatus event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());

    // Перевіряємо чи користувач залогінений
    final isLoggedIn = await storageService.isUserLoggedIn();

    if (isLoggedIn) {
      // Отримуємо збережені дані користувача
      final email = await storageService.getUserEmail();
      final password = await storageService.getUserPassword();

      if (email != null && password != null) {
        // Створюємо об'єкт UserData з збережених даних
        final userData = UserData(
          id: '1', // Можна згенерувати унікальний ID або зберегти його окремо
          name: email.split('@')[0], // Використовуємо частину email як ім'я
          email: email,
          password: password,
        );

        emit(HomeLoggedIn(user: userData));
      } else {
        // Якщо дані пошкоджені, очищаємо їх
        await storageService.clearUserCredentials();
        emit(HomeInitial());
      }
    } else {
      emit(HomeInitial());
    }
  }

  Future<void> _onLogoutUser(LogoutUser event, Emitter<HomeState> emit) async {
    // Очищаємо дані користувача
    await storageService.clearUserCredentials();
    emit(HomeInitial());
  }
}
