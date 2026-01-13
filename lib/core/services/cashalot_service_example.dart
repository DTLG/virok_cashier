/// Приклад використання CashalotService
/// 
/// Цей файл демонструє, як використовувати CashalotService
/// для реєстрації чеків та роботи зі змінами

import 'cashalot_service.dart';
import '../models/cashalot_models.dart';

/// Приклад: Реєстрація продажу
/// 
/// Коли користувач натискає кнопку "Оплатити",
/// викликається цей метод для реєстрації чека
Future<void> exampleRegisterSale(
  CashalotService cashalotService,
  List<CartItem> cart,
  String cashierName,
  String paymentMethod, // "ГОТІВКА" або "КАРТКА"
  int prroFiscalNum,
) async {
  try {
    // 1. Формуємо тіло чека з кошика
    final checkBody = cart.map((item) => CheckBodyRow(
          code: item.id,
          name: item.name,
          amount: item.quantity.toDouble(),
          price: item.price,
        )).toList();

    final totalSum = checkBody.fold(0.0, (sum, item) => sum + item.cost);

    final payload = CheckPayload(
      checkHead: CheckHead(
        docType: "SaleGoods",
        docSubType: "CheckGoods",
        cashier: cashierName,
      ),
      checkTotal: CheckTotal(sum: totalSum),
      checkBody: checkBody,
      checkPay: [
        CheckPayRow(
          payFormNm: paymentMethod,
          sum: totalSum,
        ),
      ],
    );

    // 2. Відправляємо запит (тут спрацює Mock або Real)
    final response = await cashalotService.registerSale(
      prroFiscalNum: prroFiscalNum,
      check: payload,
    );

    if (response.isSuccess) {
      // 3. Друкуємо чек з response.visualization
      print(response.visualization ?? '');
      // 4. Показуємо QR код з response.qrCode (якщо потрібно)
      // showQrDialog(response.qrCode);
    } else {
      // 5. Показуємо помилку
      print('Помилка: ${response.errorMessage}');
    }
  } catch (e) {
    print("Помилка зв'язку з ПРРО: $e");
  }
}

/// Приклад: Відкриття зміни
Future<void> exampleOpenShift(
  CashalotService cashalotService,
  int prroFiscalNum,
) async {
  try {
    final response = await cashalotService.openShift(
      prroFiscalNum: prroFiscalNum,
    );

    if (response.isSuccess) {
      print('Зміна відкрита. ФН: ${response.numFiscal}');
    } else {
      print('Помилка відкриття зміни: ${response.errorMessage}');
    }
  } catch (e) {
    print("Помилка: $e");
  }
}

/// Приклад: Службове внесення (розмін)
Future<void> exampleServiceDeposit(
  CashalotService cashalotService,
  int prroFiscalNum,
  double amount,
  String cashierName,
) async {
  try {
    final response = await cashalotService.serviceDeposit(
      prroFiscalNum: prroFiscalNum,
      amount: amount,
      cashier: cashierName,
    );

    if (response.isSuccess) {
      print('Службове внесення виконано. ФН: ${response.numFiscal}');
      print(response.visualization ?? '');
    } else {
      print('Помилка: ${response.errorMessage}');
    }
  } catch (e) {
    print("Помилка: $e");
  }
}

/// Приклад: Закриття зміни (Z-звіт)
Future<void> exampleCloseShift(
  CashalotService cashalotService,
  int prroFiscalNum,
) async {
  try {
    final response = await cashalotService.closeShift(
      prroFiscalNum: prroFiscalNum,
    );

    if (response.isSuccess) {
      print('Зміна закрита. Z-звіт сформовано.');
      print(response.visualization ?? '');
    } else {
      print('Помилка закриття зміни: ${response.errorMessage}');
    }
  } catch (e) {
    print("Помилка: $e");
  }
}

/// Приклад: Отримання доступних ПРРО
Future<void> exampleGetAvailablePrros(CashalotService cashalotService) async {
  try {
    final prros = await cashalotService.getAvailablePrros();
    print('Доступні ПРРО: $prros');
  } catch (e) {
    print("Помилка: $e");
  }
}

/// Приклад використання в main.dart або DI-контейнері
/// 
/// ```dart
/// void main() {
///   // ЗАРАЗ: Використовуємо MOCK
///   CashalotService cashalotService = MockCashalotService();
///
///   // ПОТІМ (коли будуть ключі):
///   // CashalotService cashalotService = RealCashalotService(
///   //   apiKey: "...",
///   //   pemKey: "...",
///   // );
///
///   runApp(MyApp(cashalotService: cashalotService));
/// }
/// ```

// Заглушка для CartItem (для прикладу)
class CartItem {
  final String id;
  final String name;
  final int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });
}

