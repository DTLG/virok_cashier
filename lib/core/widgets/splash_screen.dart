import 'package:flutter/material.dart';
import 'package:cash_register/core/widgets/notificarion_toast/view.dart';
import 'package:cash_register/core/services/sync/app_initialization_service.dart';
import 'package:cash_register/core/routes/app_router.dart';

/// Splash екран, який відповідає за початкову ініціалізацію додатку
/// і маршрутизацію користувача на потрібну сторінку.
///
/// Послідовність роботи сторінки:
/// 1) Показує скілетон (лого + прогрес бар + статус)
/// 2) Виконує ініціалізацію залежностей та перевірку стану даних
/// 3) Приймає рішення куди переходити (Home або AdvancedSyncTest)
/// 4) Якщо сталася помилка — показує тост і кнопку «Спробувати ще раз»
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _statusMessage = 'Ініціалізація...';

  // Константи для невеликих технічних пауз (для плавності UX)
  static const Duration _depsDelay = Duration(milliseconds: 500);
  static const Duration _finalizeDelay = Duration(milliseconds: 300);
  static const Duration _toastDelay = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Основна функція запуску. Виконує покрокову ініціалізацію додатку
  /// та навігацію в залежності від результату перевірок.
  ///
  /// Кроки:
  /// - Оновити статус «Ініціалізація залежностей...» і зробити коротку паузу
  /// - Викликати AppInitializationService.checkDataAndInitialize()
  /// - Показати «Завершення ініціалізації...» і зробити коротку паузу
  /// - Виконати навігацію (Home або AdvancedSyncTest)
  /// - Якщо є текст помилки, показати його тостом
  Future<void> _initializeApp() async {
    try {
      _updateStatus('Ініціалізація залежностей...');
      await _safeDelay(_depsDelay);

      _updateStatus('Перевірка стану даних...');
      final initResult =
          await AppInitializationService.checkDataAndInitialize();

      if (!mounted) return;

      _updateStatus('Завершення ініціалізації...');
      await _safeDelay(_finalizeDelay);

      await _navigateToDestination(initResult.destination);
      await _showInitErrorIfAny(initResult.errorMessage);
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Помилка ініціалізації: $e');
        _showRetryButton();
      }
    }
  }

  /// Оновлює текст статусу на Splash екрані
  void _updateStatus(String message) {
    setState(() => _statusMessage = message);
  }

  /// Безпечна затримка з перевіркою, що віджет ще змонтований
  Future<void> _safeDelay(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Переходить на потрібний екран в залежності від результату ініціалізації
  Future<void> _navigateToDestination(AppInitDestination destination) async {
    switch (destination) {
      case AppInitDestination.home:
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
        break;
      case AppInitDestination.sync:
        Navigator.of(context).pushReplacementNamed(AppRouter.advancedSyncTest);
        break;
    }
  }

  /// Показує тост з помилкою (якщо вона є) після невеликої затримки
  Future<void> _showInitErrorIfAny(String? errorMessage) async {
    if (errorMessage == null || !mounted) return;
    await _safeDelay(_toastDelay);
    if (!mounted) return;
    ToastManager.show(context, type: ToastType.error, title: errorMessage);
  }

  /// Вмикає кнопку «Спробувати ще раз» (та оновлює статус)
  void _showRetryButton() {
    setState(() {
      _statusMessage = 'Сталася помилка. Спробуйте ще раз.';
    });
  }

  @override
  Widget build(BuildContext context) {
    // UI складається з логотипу, прогрес-бару, статусу і (за потреби) кнопки повтору
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип або іконка
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.8 + (_animation.value * 0.2),
                      child: Icon(
                        Icons.receipt_long,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Назва додатку
              Text(
                'Cash Register',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Система обліку товарів',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),

              const SizedBox(height: 60),

              // Індикатор завантаження
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                ),
              ),

              const SizedBox(height: 16),

              // Статус
              Text(
                _statusMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Кнопка повтору (показується при помилці)
              if (_statusMessage.contains('помилка') ||
                  _statusMessage.contains('скасована'))
                ElevatedButton(
                  onPressed: () {
                    setState(
                      () => _statusMessage = 'Повторна ініціалізація...',
                    );
                    _initializeApp();
                  },
                  child: const Text('Спробувати ще раз'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
