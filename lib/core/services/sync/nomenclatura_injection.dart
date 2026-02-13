// DEPRECATED: Use AppInitializationService instead
// This file is kept for backward compatibility

import 'app_initialization_service.dart';

@Deprecated('Use AppInitializationService.initializeDependencies() instead')
Future<void> initNomenclaturaInjection() async {
  await AppInitializationService.initializeDependencies();
}
