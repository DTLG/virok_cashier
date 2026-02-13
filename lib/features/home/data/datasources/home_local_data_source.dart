import '../../../../core/services/storage/storage_service.dart';

abstract class HomeLocalDataSource {
  Future<bool> isUserLoggedIn();
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  final StorageService storageService;
  HomeLocalDataSourceImpl(this.storageService);

  @override
  Future<bool> isUserLoggedIn() async {
    return await storageService.isUserLoggedIn();
  }
}
