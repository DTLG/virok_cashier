import 'package:get_it/get_it.dart';
import '../../features/home/data/datasources/home_local_data_source.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/check_user_login_status.dart';
import '../../features/home/domain/usecases/get_last_opened_shift.dart';
import '../../features/home/domain/usecases/open_today_shift.dart';
import '../../features/home/domain/usecases/close_previous_shift.dart';
import '../../features/home/domain/usecases/checkout.dart';
import 'package:cash_register/core/services/storage/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt _sl = GetIt.instance;

void setupHomeInjection() {
  // Data sources
  _sl.registerLazySingleton<HomeLocalDataSource>(
    () => HomeLocalDataSourceImpl(_sl<StorageService>()),
  );
  _sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(Supabase.instance.client),
  );

  // Repository
  _sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remote: _sl<HomeRemoteDataSource>(),
      local: _sl<HomeLocalDataSource>(),
    ),
  );

  // Use cases
  _sl.registerFactory(() => CheckUserLoginStatus(_sl<HomeRepository>()));
  _sl.registerFactory(() => GetLastOpenedShift(_sl<HomeRepository>()));
  _sl.registerFactory(() => OpenTodayShift(_sl<HomeRepository>()));
  _sl.registerFactory(() => ClosePreviousShift(_sl<HomeRepository>()));
  _sl.registerFactory(() => Checkout(_sl<HomeRepository>()));
}
