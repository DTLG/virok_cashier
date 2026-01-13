# Налаштування RealCashalotService

## Опис

`RealCashalotService` - це реальна реалізація `CashalotService`, яка використовує `CashalotApiClient` для роботи з реальним API Cashalot.

**Важливо:** API фіскального сервера (FSAPI) не використовує авторизацію через username/password. Замість цього, в кожному запиті передаються:
- **Certificate** (Base64) - сертифікат
- **PrivateKey** (Base64) - приватний ключ
- **Password** - пароль від ключа

## Встановлення

### 1. Додавання ключів в проєкт

Створіть папку `assets/keys/` в корені проєкту та покладіть туди файли:
- `Key-6.dat` - приватний ключ
- `Cert.crt` - сертифікат

Додайте в `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/keys/
```

### 2. Базове використання

```dart
import 'core/services/real_cashalot_service.dart';

final cashalotService = RealCashalotService(
  baseUrl: 'https://fsapi.cashalot.org.ua',
  keyPath: 'assets/keys/Key-6.dat',
  certPath: 'assets/keys/Cert.crt',
  keyPassword: 'ваш_пароль_від_ключа',
  defaultPrroFiscalNum: '4000000001',
);
```

### 3. Використання через DI

Оновіть `lib/core/di/cashalot_injection.dart`:

```dart
setupCashalotInjection(
  useReal: true,
  baseUrl: 'https://fsapi.cashalot.org.ua',
  keyPath: 'assets/keys/Key-6.dat',
  certPath: 'assets/keys/Cert.crt',
  keyPassword: 'ваш_пароль_від_ключа',
  defaultPrroFiscalNum: '4000000001',
);
```

Потім в `app_initialization_service.dart`:

```dart
setupCashalotInjection(
  useReal: true,
  baseUrl: 'https://fsapi.cashalot.org.ua',
  keyPath: 'assets/keys/Key-6.dat',
  certPath: 'assets/keys/Cert.crt',
  keyPassword: 'ваш_пароль_від_ключа',
  defaultPrroFiscalNum: '4000000001',
);
```

## Особливості реалізації

### Завантаження ключів

Ключі завантажуються з assets при першому запиті та кешуються в пам'яті (Base64). Це означає, що файли читаються тільки один раз.

### Структура запиту

Кожен запит до API містить ключі в корені JSON:

```json
{
  "Command": "RegisterCheck",
  "NumFiscal": "4000000001",
  "Certificate": "base64_encoded_cert...",
  "PrivateKey": "base64_encoded_key...",
  "Password": "password",
  "CHECKHEAD": { ... },
  "CHECKBODY": [ ... ],
  "CHECKTOTAL": { ... },
  "CHECKPAY": [ ... ]
}
```

### Endpoint

За замовчуванням використовується `/api/v1/register`. Якщо ваш API використовує інший endpoint, змініть його в `CashalotApiClient`.

## Приклад використання

```dart
// Створення сервісу
final cashalotService = RealCashalotService(
  baseUrl: 'https://fsapi.cashalot.org.ua',
  keyPath: 'assets/keys/Key-6.dat',
  certPath: 'assets/keys/Cert.crt',
  keyPassword: 'your_key_password',
  defaultPrroFiscalNum: '4000000001',
);

// Отримання доступних ПРРО
final prros = await cashalotService.getAvailablePrros();
print('Доступні ПРРО: $prros');

// Відкриття зміни
final openResponse = await cashalotService.openShift(
  prroFiscalNum: int.parse(prros.first),
);
if (openResponse.isSuccess) {
  print('Зміна відкрита: ${openResponse.numFiscal}');
}

// Реєстрація продажу
final checkPayload = CheckPayload(
  checkHead: CheckHead(cashier: 'Іванов І.І.'),
  checkTotal: CheckTotal(sum: 100.0),
  checkBody: [
    CheckBodyRow(
      code: '12345',
      name: 'Товар',
      amount: 1.0,
      price: 100.0,
    ),
  ],
  checkPay: [
    CheckPayRow(payFormNm: 'ГОТІВКА', sum: 100.0),
  ],
);

final saleResponse = await cashalotService.registerSale(
  prroFiscalNum: int.parse(prros.first),
  check: checkPayload,
);

if (saleResponse.isSuccess) {
  print('Чек зареєстровано: ${saleResponse.numFiscal}');
  print('QR код: ${saleResponse.qrCode}');
  print('Візуалізація: ${saleResponse.visualization}');
}
```

## Логування

`RealCashalotService` використовує `debugPrint` для детального логування:
- Завантаження ключів
- Всі запити до API
- Параметри запитів
- Відповіді від сервера
- Помилки

Логи мають префікс `[CASHALOT]` для легкого пошуку.

## Перемикання між Mock та Real

Для перемикання між Mock та Real реалізацією достатньо змінити параметр `useReal` в `setupCashalotInjection()`:

```dart
// Mock (для розробки)
setupCashalotInjection(useReal: false);

// Real (для продакшну)
setupCashalotInjection(
  useReal: true,
  baseUrl: 'https://fsapi.cashalot.org.ua',
  keyPath: 'assets/keys/Key-6.dat',
  certPath: 'assets/keys/Cert.crt',
  keyPassword: 'your_key_password',
  defaultPrroFiscalNum: '4000000001',
);
```

Весь інший код залишається без змін!

## Безпека

⚠️ **ВАЖЛИВО:** Не комітьте файли ключів в Git!

Додайте в `.gitignore`:
```
assets/keys/*.dat
assets/keys/*.crt
assets/keys/*.pem
```
