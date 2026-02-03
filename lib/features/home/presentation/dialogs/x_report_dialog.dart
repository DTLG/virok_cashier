import 'dart:convert'; // 1. Для декодування Base64
import 'package:flutter/material.dart';
import '../../../../services/x_report_data.dart';

/// Діалог для відображення звіту (X або Z)
class XReportDialog extends StatelessWidget {
  final XReportData reportData;
  final String title;
  final String? visualization; // 2. Додаємо поле для Base64 рядка
  final bool isZRep; // Можна додати прапорець, щоб розрізняти X та Z
  const XReportDialog({
    super.key,
    required this.reportData,
    this.title = 'X-Звіт',
    this.isZRep = false,
    this.visualization, // Приймаємо його в конструкторі
  });

  // 3. Метод для декодування
  String _decodeVisualization(String base64Str) {
    try {
      // Очищаємо від можливих пробілів/переносів, якщо вони є
      final cleanStr = base64Str.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64.decode(cleanStr);
      return utf8.decode(bytes);
    } catch (e) {
      return 'Не вдалося декодувати чек: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(
          maxHeight: 800,
        ), // Трохи збільшив висоту
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
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                    // === СЕКЦІЯ ВІЗУАЛІЗАЦІЇ (НОВА) ===
                    if (visualization != null && visualization!.isNotEmpty)
                      _buildSection('Візуалізація чека', [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1E1E1E,
                            ), // Темніший фон для "паперу"
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            // Щоб можна було копіювати текст
                            _decodeVisualization(visualization!),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily:
                                  'monospace', // ВАЖЛИВО: для рівних колонок
                              fontSize: 12,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ]),

                    if (visualization != null) const SizedBox(height: 16),

                    // Загальна інформація
                    _buildSection('Загальна інформація', [
                      _buildInfoRow('Дата/Час', reportData.dt ?? 'N/A'),
                      _buildInfoRow('ПРРО', reportData.fisid ?? 'N/A'),
                      _buildInfoRow('Касир', reportData.cashier ?? 'N/A'),
                      _buildInfoRow(
                        'Режим',
                        reportData.isOffline ? 'Офлайн' : 'Онлайн',
                      ),
                      _buildInfoRow(
                        'Залишок готівки',
                        '${reportData.safe.toStringAsFixed(2)} грн',
                      ),
                      _buildInfoRow(
                        'Залишок на початок зміни',
                        '${reportData.safeStartShift.toStringAsFixed(2)} грн',
                      ),
                      if (reportData.shiftLink != null)
                        _buildInfoRow(
                          'Поточний номер Z-звіту',
                          reportData.shiftLink.toString(),
                        ),
                    ]),

                    const SizedBox(height: 16),

                    // Підсумки по чеках
                    if (reportData.receipt != null)
                      _buildSection('Підсумки по чеках', [
                        _buildInfoRow(
                          'Чеків на продаж',
                          reportData.receipt!.countP.toString(),
                        ),
                        _buildInfoRow(
                          'Чеків повернення',
                          reportData.receipt!.countM.toString(),
                        ),
                        _buildInfoRow(
                          'Чеків видачі готівки',
                          reportData.receipt!.count14.toString(),
                        ),
                        _buildInfoRow(
                          'Останній чек продажу',
                          reportData.receipt!.lastDocnoP.toString(),
                        ),
                        _buildInfoRow(
                          'Останній чек повернення',
                          reportData.receipt!.lastDocnoM.toString(),
                        ),
                      ]),

                    const SizedBox(height: 16),

                    // Загальні підсумки
                    if (reportData.summary != null)
                      _buildSection('Загальні підсумки', [
                        _buildInfoRow(
                          'Оборот продажу',
                          '${reportData.summary!.calcP.toStringAsFixed(2)} грн',
                        ),
                        _buildInfoRow(
                          'Оборот повернення',
                          '${reportData.summary!.calcM.toStringAsFixed(2)} грн',
                        ),
                        _buildInfoRow(
                          'Знижка продажу',
                          '${reportData.summary!.discP.toStringAsFixed(2)} грн',
                        ),
                        _buildInfoRow(
                          'Знижка повернення',
                          '${reportData.summary!.discM.toStringAsFixed(2)} грн',
                        ),
                      ]),

                    const SizedBox(height: 16),

                    // Оплати
                    if (reportData.pays.isNotEmpty)
                      _buildSection(
                        'Оплати',
                        reportData.pays.map((pay) {
                          final total = pay.sumP - pay.sumM;
                          return _buildInfoRow(
                            pay.name,
                            '${total.toStringAsFixed(2)} грн',
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Податки
                    if (reportData.taxes.isNotEmpty)
                      _buildSection(
                        'Податки',
                        reportData.taxes.map((tax) {
                          final total = tax.taxSumP - tax.taxSumM;
                          return _buildInfoRow(
                            '${tax.taxName} (${tax.taxPercent}%)',
                            '${total.toStringAsFixed(2)} грн',
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Попередження
                    if (reportData.warnings.isNotEmpty)
                      _buildSection(
                        'Попередження',
                        reportData.warnings.map((warning) {
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

            // Кнопка закриття
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Готово',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
