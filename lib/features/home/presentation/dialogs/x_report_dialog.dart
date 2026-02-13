import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml; // Імпорт пакету XML
import 'package:enough_convert/enough_convert.dart';
import '../../../../core/models/x_report_data.dart';
import '../../../../core/services/printing/raw_printer_service.dart';
import '../../../../core/widgets/notificarion_toast/toast_manager.dart';
import '../../../../core/widgets/notificarion_toast/toast_type.dart';

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
  bool _isPrinting = false;

  // 1. Декодуємо Base64 -> Windows1251 -> String (З ТЕГАМИ)
  String _decodeXmlString(String base64Str) {
    try {
      final cleanStr = base64Str.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64.decode(cleanStr);
      // Важливо: повертаємо чистий XML з тегами для парсингу
      return const Windows1251Codec(allowInvalid: true).decode(bytes);
    } catch (e) {
      return '';
    }
  }

  // 2. Метод для створення красивого рядка даних
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Головний метод парсингу XML та побудови UI
  Widget _buildParsedReport(String xmlString) {
    if (xmlString.isEmpty) {
      return const Text(
        'Не вдалося прочитати дані звіту',
        style: TextStyle(color: Colors.red),
      );
    }

    try {
      final document = xml.XmlDocument.parse(xmlString);

      // Функція-хелпер для безпечного отримання тексту тега
      String getTag(String name) {
        return document.findAllElements(name).firstOrNull?.innerText ?? '';
      }

      // Форматування дати та часу
      String date = getTag('ORDERDATE'); // 11022026
      String time = getTag('ORDERTIME'); // 152342

      if (date.length == 8) {
        date =
            '${date.substring(0, 2)}.${date.substring(2, 4)}.${date.substring(4)}';
      }
      if (time.length >= 6) {
        time =
            '${time.substring(0, 2)}:${time.substring(2, 4)}:${time.substring(4)}';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === ШАПКА ===
          _buildInfoRow('Організація', getTag('ORGNM'), isBold: true),
          _buildInfoRow('Торгова точка', getTag('POINTNM')),
          _buildInfoRow('Адреса', getTag('POINTADDR')),
          const Divider(color: Colors.white24),

          // === РЕКВІЗИТИ ===
          _buildInfoRow('ЄДРПОУ (TIN)', getTag('TIN')),
          _buildInfoRow('ІПН', getTag('IPN')),
          _buildInfoRow('ФН ПРРО', getTag('CASHREGISTERNUM')),
          _buildInfoRow('Каса №', getTag('CASHDESKNUM')),
          const Divider(color: Colors.white24),

          // === ДАНІ ЧЕКА ===
          _buildInfoRow('Дата', date),
          _buildInfoRow('Час', time),
          _buildInfoRow('Номер Z-звіту', getTag('ORDERNUM'), isBold: true),
          _buildInfoRow('Касир', getTag('CASHIER')),
          const Divider(color: Colors.white24),

          // === ФІНАНСОВІ ДАНІ (ZREPBODY) ===
          // Тут можна додати інші поля, які є у вашому XML (SALES, RETURNS і т.д.)
          _buildInfoRow('Службове внесення', getTag('SERVICEINPUT')),
          _buildInfoRow('Службова видача', getTag('SERVICEOUTPUT')),

          // Якщо є коментар Cashalot
          if (getTag('CASHALOTCOMMENT').isNotEmpty)
            _buildInfoRow('Примітка', getTag('CASHALOTCOMMENT')),
        ],
      );
    } catch (e) {
      debugPrint('XML Parse Error: $e');
      // Якщо парсинг впав, показуємо сирий текст як запасний варіант
      return SelectableText(
        xmlString.replaceAll(
          RegExp(r'<[^>]*>'),
          '',
        ), // Вирізаємо теги для читабельності
        style: const TextStyle(color: Colors.white),
      );
    }
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    final rawPrinterService = RawPrinterService();

    try {
      await rawPrinterService.printVisualization(
        visualizationBase64: widget.reportData.visualization!,
      );

      if (!mounted) return;
      ToastManager.show(
        context,
        type: ToastType.success,
        title: 'Друк успішний',
        message: 'Чек успішно відправлено на принтер',
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Помилка друку: $e");
      if (!mounted) return;
      setState(() => _isPrinting = false);

      ToastManager.show(
        context,
        type: ToastType.error,
        title: 'Помилка друку',
        message: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Отримуємо XML рядок
    final xmlString = _decodeXmlString(widget.reportData.visualization ?? '');

    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Container(
        width: 500, // Трохи зменшив ширину для акуратності
        constraints: const BoxConstraints(maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isZRep ? Icons.assessment : Icons.receipt_long,
                    color: Colors.blue,
                  ),
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
                  if (!_isPrinting)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildParsedReport(xmlString),
              ),
            ),

            // Footer (Buttons)
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
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handlePrint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
