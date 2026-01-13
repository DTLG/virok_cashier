import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';

/// Допоміжний клас для роботи з PDF-файлами з Base64
class PdfHelper {
  /// Декодує Base64, зберігає у файл та відкриває його
  ///
  /// [base64String] - Base64-рядок PDF-файлу
  /// [fileName] - назва файлу без розширення (буде додано .pdf)
  static Future<void> saveAndOpenBase64Pdf(
    String base64String,
    String fileName,
  ) async {
    try {
      // 1. Декодуємо рядок у байти
      final bytes = base64Decode(base64String);

      // 2. Отримуємо шлях до тимчасової папки або документів
      final directory = await getApplicationDocumentsDirectory();
      // Або getTemporaryDirectory() якщо не хочете смітити

      final filePath = '${directory.path}/$fileName.pdf';
      final file = File(filePath);

      // 3. Записуємо байти у файл
      await file.writeAsBytes(bytes);
      debugPrint("💾 PDF збережено: $filePath");

      // 4. Відкриваємо файл стандартним переглядачем системи
      final result = await OpenFilex.open(filePath);
      debugPrint("📂 Статус відкриття: ${result.type}");

      if (result.type != ResultType.done) {
        debugPrint("⚠️ [PDF] Не вдалося відкрити файл: ${result.message}");
      }
    } catch (e) {
      debugPrint("❌ Помилка при збереженні/відкритті PDF: $e");
    }
  }
}
