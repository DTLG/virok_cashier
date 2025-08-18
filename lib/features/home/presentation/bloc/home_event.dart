part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

final class CheckUserLoginStatus extends HomeEvent {
  const CheckUserLoginStatus();
}

final class LogoutUser extends HomeEvent {
  const LogoutUser();
}
