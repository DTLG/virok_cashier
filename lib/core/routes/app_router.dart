import 'package:flutter/material.dart';
import '../../features/login/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/nomenclatura/test_page.dart';
import '../../features/nomenclatura/advanced_sync_test_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
// import '../../features/nomenclatura/presentation/pages/realtime_test_page.dart';
import '../widgets/splash_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String nomenclaturaTest = '/nomenclatura-test';
  static const String advancedSyncTest = '/advancedSyncTest';
  // static const String realtimeTest = '/realtime-test';

  static Route<dynamic> generateRoute(RouteSettings route) {
    switch (route.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case nomenclaturaTest:
        return MaterialPageRoute(builder: (_) => const NomenclaturaTestPage());
      case advancedSyncTest:
        return MaterialPageRoute(builder: (_) => const AdvancedSyncTestPage());
      // case realtimeTest:
      //   return MaterialPageRoute(builder: (_) => const RealtimeTestPage());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
