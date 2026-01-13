import 'package:flutter/material.dart';

Future<void> showShiftAlreadyOpenDialog(
  BuildContext context, {
  required DateTime openedAt,
}) async {
  final timeStr = _formatTime(openedAt);
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Зміна вже відкрита',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Зміна вже була відкрита о $timeStr.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

String _formatTime(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
