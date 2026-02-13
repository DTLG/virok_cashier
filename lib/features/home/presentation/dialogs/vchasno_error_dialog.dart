import 'package:flutter/material.dart';
import '../../../../core/models/vchasno_errors.dart';
import '../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../core/widgets/notificarion_toast/toast_type.dart';

/// Діалог для обробки помилок Vchasno
Future<void> showVchasnoErrorDialog(
  BuildContext context,
  VchasnoException error,
) async {
  switch (error.type) {
    case VchasnoErrorType.shiftTooLong:
      // Блокуючий екран - потрібен Z-звіт
      return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Необхідно закрити зміну',
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
          content: Text(
            error.message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Зрозуміло'),
            ),
          ],
        ),
      );

    case VchasnoErrorType.noPaper:
      // Alert про папір
      return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Закінчився папір',
            style: TextStyle(color: Colors.orange),
          ),
          content: const Text(
            'Вставте папір у принтер',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

    case VchasnoErrorType.noConnection:
    case VchasnoErrorType.networkTimeout:
      // Діалог з кнопкою "Повторити"
      return await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Помилка з\'єднання',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            error.message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Повторити'),
            ),
          ],
        ),
      );

    case VchasnoErrorType.shiftClosed:
      // Показуємо тост - зміна вже відкрита автоматично
      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Зміна була закрита',
        message: 'Спроба автоматичного відкриття зміни...',
      );
      return;

    case VchasnoErrorType.validationError:
      // Логуємо помилку валідації (вже зроблено в сервісі)
      return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Помилка валідації',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            '${error.message}\n\nКод помилки: ${error.errorCode ?? "N/A"}\n\n'
            'Деталі помилки відправлено для аналізу.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

    case VchasnoErrorType.unknown:
      // Загальна помилка
      return await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Помилка', style: TextStyle(color: Colors.red)),
          content: Text(
            error.message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (error.canRetry)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Повторити'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('OK'),
            ),
          ],
        ),
      );
  }
}
