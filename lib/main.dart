import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'dart:ui';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/config/supabase_config.dart';
import 'core/routes/app_router.dart';
import 'core/services/app_initialization_service.dart';
import 'core/services/storage_service.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/home/presentation/bloc/home_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Обробка помилок клавіатури на Windows
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ігноруємо помилки клавіатури, які не впливають на функціональність
    if (details.exception.toString().contains('RawKeyDownEvent') ||
        details.exception.toString().contains('keysPressed') ||
        details.exception.toString().contains('keyboard') ||
        details.exception.toString().contains('Unable to parse JSON message')) {
      return; // Ігноруємо помилки клавіатури та JSON парсингу
    }
    FlutterError.presentError(details);
  };

  // Обробка помилок платформних повідомлень
  PlatformDispatcher.instance.onError = (error, stack) {
    // Ігноруємо помилки клавіатури та JSON парсингу
    if (error.toString().contains('RawKeyDownEvent') ||
        error.toString().contains('keysPressed') ||
        error.toString().contains('keyboard') ||
        error.toString().contains('Unable to parse JSON message')) {
      return true; // Помилка оброблена
    }
    return false; // Показуємо інші помилки
  };

  // Ініціалізуємо SQLite для desktop платформ
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    // Логуємо помилку, але не зупиняємо додаток
    print('Supabase initialization error: $e');
  }

  // Ініціалізуємо залежності
  try {
    await AppInitializationService.initializeDependencies();
  } catch (e) {
    print('Dependencies initialization error: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return
    //  MultiBlocProvider(
    //   create: (context) {
    //     try {
    //       return AppInitializationService.get<SettingsBloc>();
    //     } catch (e) {
    //       print('Error getting SettingsBloc: $e');
    //       // Повертаємо новий SettingsBloc як fallback
    //       return SettingsBloc(storageService: StorageService());
    //     }
    //   },
    MultiBlocProvider(
      providers: [
        // 1. Settings Bloc
        BlocProvider<SettingsBloc>(
          create: (_) => AppInitializationService.get<SettingsBloc>(),
        ),

        // 2. Home Bloc (Додаємо сюди!)
        BlocProvider<HomeBloc>(
          create: (context) => AppInitializationService.get<HomeBloc>()
            ..add(
              GetAvailablePrrosInfo(),
            ), // Запускаємо отримання кас при старті
        ),
      ],
      child: MaterialApp(
        title: 'Каса Virok',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
        ),
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
