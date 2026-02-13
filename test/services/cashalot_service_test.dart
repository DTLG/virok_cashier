import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_register/core/services/cashalot/com/cashalot_com_service.dart'; // Змініть шлях на ваш
import 'package:cash_register/core/models/cashalot_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CashalotComService service;

  // Канал, який ми будемо мокати
  const MethodChannel channel = MethodChannel('cashalot_channel');

  setUp(() {
    service = CashalotComService();
  });

  tearDown(() {
    // Очищаємо мок після кожного тесту
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('CashalotComService Tests', () {
    test('registerSale повертає успішний Response при валідних даних', () async {
      // 1. ARRANGE (Підготовка)
      // Імітуємо те, що повертає C++ DLL
      final mockCppResponse = {
        'success': true,
        'jsonVal':
            '{"Values": {"ReceiptFiscalNumber": "12345", "RRN": "test_rrn"}, "Ret": true}',
      };

      // Перехоплюємо виклик до каналу
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'fiscalizeCheck') {
              // Тут можна перевірити, чи правильно ми передали аргументи в C++
              // expect(methodCall.arguments['fiscalNum'], '4000...');
              return mockCppResponse;
            }
            return null;
          });

      // 2. ACT (Дія)
      // Викликаємо ваш метод (потрібно підставити ваші реальні обєкти CheckPayload)
      // Для тесту можна передати спрощені дані або моки, якщо метод дозволяє
      final result = await service.registerSale(
        prroFiscalNum: 4000123456,
        check:
            CheckPayload.empty(), // Припустимо, у вас є пустий конструктор або стаб
      );

      // 3. ASSERT (Перевірка)
      expect(result.errorCode, isNull);
      expect(result.data, isNotNull);
      expect(result.data!['ReceiptFiscalNumber'], '12345');
    });

    test('registerSale повертає помилку, якщо C++ повернув false', () async {
      // 1. ARRANGE
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'fiscalizeCheck') {
              return {
                'success': false,
                'jsonVal': '{"ErrorString": "COM Error occurred"}',
              };
            }
            return null;
          });

      // 2. ACT
      final result = await service.registerSale(
        prroFiscalNum: 4000123456,
        check: CheckPayload.empty(),
      );

      // 3. ASSERT
      expect(result.errorCode, 'API_ERROR');
      expect(result.errorMessage, contains('COM Error'));
    });
  });
}
