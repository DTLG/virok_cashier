import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:enough_convert/enough_convert.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/storage_service.dart'; // Переконайтеся, що шлях правильний
import '../../core/config/vchasno_config.dart'; // Для дефолтних значень, якщо є

class RawPrinterService {
  final StorageService _storageService;

  // Конструктор: бере StorageService з GetIt автоматично,
  // але дозволяє передати вручну для тестів.
  RawPrinterService({StorageService? storageService})
    : _storageService = storageService ?? GetIt.instance<StorageService>();

  // --- ПРИВАТНІ МЕТОДИ ОТРИМАННЯ НАЛАШТУВАНЬ ---

  /// Отримує збережений IP або null
  Future<String?> _getSavedIp() async {
    return await _storageService.getString('printer_ip');
  }

  /// Отримує збережений порт або дефолтний 9100
  Future<int> _getSavedPort() async {
    final savedPort = await _storageService.getInt('printer_port');
    return savedPort ?? 9100; // 9100 - стандарт для RAW друку
  }

  // --- ПУБЛІЧНІ МЕТОДИ ДРУКУ ---

  /// Друкує візуалізацію (X-звіт, Z-звіт, Чек) з поля visualization
  ///
  /// Якщо [printerIp] або [port] не передані, бере їх з SharedPreferences.
  Future<void> printVisualization({
    required String? visualizationBase64,
    String? printerIp,
    int? port,
  }) async {
    if (visualizationBase64 == null || visualizationBase64.isEmpty) {
      debugPrint("⚠️ [PRINTER] Немає даних для друку");
      return;
    }

    // 1. Визначаємо адресу та порт (Аргумент -> Storage -> Помилка)
    final targetIp = printerIp ?? await _getSavedIp();
    final targetPort = port ?? await _getSavedPort();

    if (targetIp == null || targetIp.isEmpty) {
      debugPrint("⚠️ [PRINTER] IP принтера не налаштовано!");
      throw Exception("Принтер не налаштовано. Перейдіть в налаштування.");
    }

    try {
      debugPrint(
        "🖨️ [PRINTER] Друкуємо візуалізацію на $targetIp:$targetPort",
      );

      final socket = await Socket.connect(
        targetIp,
        targetPort,
        timeout: const Duration(seconds: 5),
      );

      List<int> bytesToSend = [];

      // Ініціалізація + Code Page 17 (PC866/Win1251)
      bytesToSend.addAll([0x1B, 0x40, 0x1B, 0x74, 17]);

      // Декодування Base64 -> UTF-8 -> Windows-1251
      String cleanBase64 = visualizationBase64.replaceAll(RegExp(r'\s+'), '');
      List<int> utf8Bytes = base64.decode(cleanBase64);
      String decodedText = utf8.decode(utf8Bytes);

      final codec = const Windows1251Codec(allowInvalid: true);
      bytesToSend.addAll(codec.encode(decodedText));

      // Footer: Feed & Cut
      bytesToSend.addAll([0x1B, 0x64, 0x04, 0x1D, 0x56, 0x42, 0x00]);

      socket.add(Uint8List.fromList(bytesToSend));
      await socket.flush();
      await socket.close();

      debugPrint("✅ [PRINTER] Друк успішний!");
    } catch (e) {
      debugPrint("❌ [PRINTER] Помилка: $e");
      rethrow;
    }
  }

  /// Друкує банківський сліп
  ///
  /// Якщо [printerIp] або [port] не передані, бере їх з SharedPreferences.
  Future<void> printBankSlip({
    required String slipText,
    String? printerIp,
    int? port,
  }) async {
    // 1. Визначаємо адресу
    final targetIp = printerIp ?? await _getSavedIp();
    final targetPort = port ?? await _getSavedPort();

    if (targetIp == null || targetIp.isEmpty) {
      debugPrint("⚠️ [PRINTER] IP принтера не налаштовано!");
      // Для сліпа можна не кидати критичну помилку, а просто логувати
      return;
    }

    try {
      debugPrint("🖨️ [PRINTER] Друкуємо сліп на $targetIp:$targetPort");

      final socket = await Socket.connect(
        targetIp,
        targetPort,
        timeout: const Duration(seconds: 5),
      );

      List<int> bytesToSend = [];
      bytesToSend.addAll([0x1B, 0x40, 0x1B, 0x74, 17]); // Init + CP17

      final codec = const Windows1251Codec(allowInvalid: true);
      bytesToSend.addAll(codec.encode(slipText));

      bytesToSend.addAll([
        0x1B,
        0x64,
        0x04,
        0x1D,
        0x56,
        0x42,
        0x00,
      ]); // Feed + Cut

      socket.add(Uint8List.fromList(bytesToSend));
      await socket.flush();
      await socket.close();
    } catch (e) {
      debugPrint("❌ [PRINTER] Помилка друку сліпа: $e");
      rethrow;
    }
  }
}
