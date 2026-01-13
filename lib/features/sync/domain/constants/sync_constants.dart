import 'package:flutter/material.dart';

class SyncConstants {
  // Colors
  static const Color primaryColor = Color(0xFF1A1A1A);
  static const Color secondaryColor = Color(0xFF2A2A2A);
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Text styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  static const TextStyle smallStyle = TextStyle(
    fontSize: 12,
    color: Colors.white70,
  );

  // Dimensions
  static const double defaultPadding = 12.0;
  static const double largePadding = 20.0;
  static const double borderRadius = 10.0;
  static const double largeBorderRadius = 12.0;

  // Messages
  static const String readyMessage = 'Готовий до роботи';
  static const String serviceInitializedMessage = 'Сервіс ініціалізовано';
  static const String serviceNotInitializedMessage = 'Сервіс не ініціалізовано';
  static const String checkingStatusMessage =
      'Перевірка статусу синхронізації...';
  static const String gettingInfoMessage = 'Отримання детальної інформації...';
  static const String syncingMessage = 'Синхронізація...';
  static const String forceSyncingMessage = 'Примусова синхронізація...';
  static const String clearingDataMessage = 'Очищення локальних даних...';

  // Button labels
  static const String statusLabel = 'Статус';
  static const String infoLabel = 'Інфо';
  static const String syncLabel = 'Синк';
  static const String forceSyncLabel = 'Примусово';
  static const String clearLabel = 'Очистити';
  static const String backToHomeLabel = 'Повернутись на головну';

  // Help text
  static const String helpText =
      '''• Перевірити статус - показує поточний стан синхронізації
• Детальна інформація - повна статистика про дані
• Синхронізація - інтерактивний діалог для налаштування
• Примусова синхронізація - очищує кеш і завантажує все заново
• Очистити дані - видаляє всі локальні дані''';
}
