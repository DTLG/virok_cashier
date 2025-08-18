part of 'home_bloc.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoggedIn extends HomeState {
  final UserData user;

  const HomeLoggedIn({required this.user});

  @override
  List<Object> get props => [user];
}
