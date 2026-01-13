import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Діалог успішного замовлення з QR-кодом
class OrderSuccessDialog extends StatelessWidget {
  final String? qrUrl;
  final String? docNumber;
  final double totalAmount;

  const OrderSuccessDialog({
    super.key,
    required this.qrUrl,
    required this.docNumber,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text(
        '✅ Чек фіскалізовано!',
        style: TextStyle(color: Colors.green, fontSize: 18),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (docNumber != null)
              Text(
                'Чек № $docNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Сума: ${totalAmount.toStringAsFixed(2)} грн',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (qrUrl != null && qrUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: qrUrl!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Відскануйте для перегляду чека',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text(
            'Новий продаж',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

