import 'package:flutter/material.dart';
import 'close_shift_dialog.dart';

Future<void> closePreviousShiftDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Попередня зміна не закрита',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Виявлено відкриту попередню зміну. Бажаєте закрити її зараз?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              // 👇 повертаємо результат внутрішнього діалогу
              Navigator.of(ctx).pop(); // закрили перший діалог
              await showCloseShiftDialog(context);
            },
            child: const Text('Закрити зараз'),
          ),
        ],
      );
    },
  );
}
