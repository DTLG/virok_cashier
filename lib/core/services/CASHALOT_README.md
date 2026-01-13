# Cashalot Service

Сервіс для роботи з API Cashalot (ПРРО - Програмно-Реалізований Реєстратор Операцій).

## Структура

```
lib/core/
├── models/
│   └── cashalot_models.dart          # Моделі даних (DTOs)
└── services/
    ├── cashalot_service.dart          # Абстрактний інтерфейс
    ├── mock_cashalot_service.dart    # Mock реалізація
    └── cashalot_service_example.dart  # Приклади використання
```

## Компоненти

### 1. Моделі даних (`cashalot_models.dart`)

- **CashalotResponse** - базовий клас відповіді від сервера
- **CheckPayload** - модель чека (заголовок, тіло, оплата, підсумок)
- **CheckHead** - заголовок чека (тип документа, касир)
- **CheckBodyRow** - рядок товару в чеку
- **CheckPayRow** - рядок оплати
- **CheckTotal** - підсумок чека

### 2. Інтерфейс (`cashalot_service.dart`)

Абстрактний клас `CashalotService` визначає контракт для роботи з ПРРО:

- `getAvailablePrros()` - отримання списку доступних ПРРО
- `openShift()` - відкриття зміни
- `registerSale()` - реєстрація продажу (звичайний чек)
- `serviceDeposit()` - службове внесення грошей (розмін)
- `serviceIssue()` - службова видача грошей (інкасація)
- `closeShift()` - закриття зміни (Z-звіт)

### 3. Mock реалізація (`mock_cashalot_service.dart`)

`MockCashalotService` імітує роботу з API без реальних запитів:
- Додає затримку для імітації мережевого запиту
- Повертає успішні відповіді з фейковими даними
- Генерує текстову візуалізацію чеків
- Використовується для розробки та тестування

## Використання

### Ініціалізація в main.dart

```dart
import 'package:flutter/material.dart';
import 'core/services/cashalot_service.dart';
import 'core/services/mock_cashalot_service.dart';

void main() {
  // ЗАРАЗ: Використовуємо MOCK
  CashalotService cashalotService = MockCashalotService();

  // ПОТІМ (коли будуть ключі):
  // CashalotService cashalotService = RealCashalotService(
  //   apiKey: "...",
  //   pemKey: "...",
  // );

  runApp(MyApp(cashalotService: cashalotService));
}
```

### Приклад: Реєстрація продажу

```dart
Future<void> onPayButton(
  CashalotService cashalotService,
  List<CartItem> cart,
  String cashierName,
  String paymentMethod,
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
          payFormNm: paymentMethod, // "ГОТІВКА" або "КАРТКА"
          sum: totalSum,
        ),
      ],
    );

    // 2. Відправляємо запит
    final response = await cashalotService.registerSale(
      prroFiscalNum: prroFiscalNum,
      check: payload,
    );

    if (response.isSuccess) {
      // 3. Друкуємо чек
      print(response.visualization ?? '');
      // 4. Показуємо QR код (якщо потрібно)
      // showQrDialog(response.qrCode);
    } else {
      showError(response.errorMessage ?? 'Помилка');
    }
  } catch (e) {
    showError("Помилка зв'язку з ПРРО: $e");
  }
}
```

### Приклад: Відкриття зміни

```dart
Future<void> openShift(
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
      print('Помилка: ${response.errorMessage}');
    }
  } catch (e) {
    print("Помилка: $e");
  }
}
```

### Приклад: Службове внесення (розмін)

```dart
Future<void> serviceDeposit(
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
      print('Службове внесення виконано.');
      print(response.visualization ?? '');
    }
  } catch (e) {
    print("Помилка: $e");
  }
}
```

### Приклад: Закриття зміни (Z-звіт)

```dart
Future<void> closeShift(
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
    }
  } catch (e) {
    print("Помилка: $e");
  }
}
```

## Життєвий цикл роботи з Cashalot (Workflow)

Типовий день роботи каси (ПРРО):

1. **Ініціалізація** - При старті програми дізнатися, які ПРРО доступні
   ```dart
   final prros = await cashalotService.getAvailablePrros();
   ```

2. **Відкриття зміни** - Якщо зміна закрита, відправити команду на відкриття
   ```dart
   await cashalotService.openShift(prroFiscalNum: prroFiscalNum);
   ```

3. **Службове внесення** - Вранці покласти розмінну монету в касу
   ```dart
   await cashalotService.serviceDeposit(
     prroFiscalNum: prroFiscalNum,
     amount: 1000.0,
     cashier: "Іванов І.І.",
   );
   ```

4. **Продажі** - Основна робота. Реєстрація чеків продажу
   ```dart
   await cashalotService.registerSale(
     prroFiscalNum: prroFiscalNum,
     check: checkPayload,
   );
   ```

5. **Службова видача** - Якщо треба забрати готівку з каси (інкасація)
   ```dart
   await cashalotService.serviceIssue(
     prroFiscalNum: prroFiscalNum,
     amount: 5000.0,
     cashier: "Іванов І.І.",
   );
   ```

6. **Z-звіт / Закриття зміни** - Кінець дня. Система фіскалізує підсумки
   ```dart
   await cashalotService.closeShift(prroFiscalNum: prroFiscalNum);
   ```

## Заміна Mock на Real реалізацію

Коли буде готова реальна реалізація `RealCashalotService`, достатньо змінити ініціалізацію:

```dart
// Було:
CashalotService cashalotService = MockCashalotService();

// Стало:
CashalotService cashalotService = RealCashalotService(
  apiKey: "...",
  pemKey: "...",
);
```

Весь інший код залишається без змін, оскільки використовується абстракція `CashalotService`.

## Примітки

- Mock реалізація додає затримку 500ms для імітації мережевого запиту
- Всі фіскальні номери генеруються на основі поточного часу
- QR код в Mock реалізації - це мінімальна Base64 стрінга (1x1 піксель)
- Візуалізація чеків генерується в текстовому форматі для друку

