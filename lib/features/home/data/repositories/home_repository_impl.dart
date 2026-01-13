import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_data_source.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remote;
  final HomeLocalDataSource local;

  HomeRepositoryImpl({required this.remote, required this.local});

  @override
  Future<void> checkoutCurrentCart() => remote.checkoutCart();

  @override
  Future<void> closePreviousShift() => remote.closePreviousShift();

  @override
  Future<DateTime?> getLastOpenedShift() => remote.getLastOpenedShift();

  @override
  Future<bool> isUserLoggedIn() => local.isUserLoggedIn();

  @override
  Future<void> openTodayShift() => remote.openTodayShift();
}
