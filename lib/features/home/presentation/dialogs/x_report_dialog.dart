import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../services/x_report_data.dart';
import '../../../../services/raw_printer_service.dart';
import '../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../core/widgets/notificarion_toast/toast_type.dart';

/// Діалог для відображення звіту (X або Z)
class XReportDialog extends StatefulWidget {
  final XReportData reportData;
  final String title;
  final String? visualization;
  final bool isZRep;

  const XReportDialog({
    super.key,
    required this.reportData,
    this.title = 'X-Звіт',
    this.isZRep = false,
    this.visualization,
  });

  @override
  State<XReportDialog> createState() => _XReportDialogState();
}

class _XReportDialogState extends State<XReportDialog> {
  // Змінна для відстеження стану друку
  bool _isPrinting = false;

  // Метод для декодування
  String _decodeVisualization(String base64Str) {
    try {
      final cleanStr = base64Str.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64.decode(cleanStr);
      return utf8.decode(bytes);
    } catch (e) {
      return 'Не вдалося декодувати чек: $e';
    }
  }

  // Метод друку
  Future<void> _handlePrint() async {
    // 1. Вмикаємо лоадер
    setState(() {
      _isPrinting = true;
    });

    final rawPrinterService = RawPrinterService();

    try {
      // 2. Виконуємо друк (await)
      await rawPrinterService.printVisualization(
        visualizationBase64: widget.reportData.visualization!,
      );

      if (!mounted) return;

      // 3. Успіх
      ToastManager.show(
        context,
        type: ToastType.success,
        title: 'Друк успішний',
        message: 'Чек успішно відправлено на принтер',
      );

      // Закриваємо діалог
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Помилка друку: $e");
      if (!mounted) return;

      // 4. Помилка - вимикаємо лоадер, щоб користувач міг спробувати ще раз
      setState(() {
        _isPrinting = false;
      });

      final errorMessage = e.toString().replaceAll('Exception:', '').trim();
      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Помилка друку',
        message: errorMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Ховаємо хрестик, якщо йде друк, щоб не переривати процес
                  if (!_isPrinting)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            // Контент з прокруткою
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === СЕКЦІЯ ВІЗУАЛІЗАЦІЇ ===
                    if (widget.reportData.visualization != null &&
                        widget.reportData.visualization!.isNotEmpty)
                      _buildSection('Візуалізація звіту', [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              _decodeVisualization(
                                widget.reportData.visualization!,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 15,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    if (widget.visualization != null)
                      const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // Попередження
                    if (widget.reportData.warnings.isNotEmpty)
                      _buildSection(
                        'Попередження',
                        widget.reportData.warnings.map((warning) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    warning.wtxt,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // === КНОПКИ або ЛОАДЕР ===
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: _isPrinting
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    )
                  : Row(
                      children: [
                        // Кнопка Друк
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _handlePrint, // Викликаємо метод обробки
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Друк',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Кнопка Готово
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors
                                    .grey[700], // Трохи інший колір для другорядної дії
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Готово',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
