# Налаштування ключів для RealCashalotService

## Крок 1: Додавання ключів в проєкт

### 1.1 Створення папки для ключів

У корені проєкту створіть папку `assets/keys/`:

```
cash_register/
├── assets/
│   └── keys/
│       ├── Key-6.dat
│       └── Cert.crt
├── lib/
└── pubspec.yaml
```

### 1.2 Додавання в pubspec.yaml

Відкрийте `pubspec.yaml` і додайте секцію `flutter: assets:`:

```yaml
flutter:
  assets:
    - assets/keys/Key-6.dat
    - assets/keys/Cert.crt
```

**Важливо:** Після додавання файлів виконайте:
```bash
flutter pub get
```

## Крок 2: Налаштування DI

Оновіть виклик `setupCashalotInjection` в `app_initialization_service.dart`:

```dart
setupCashalotInjection(
  useReal: true, // Вмикаємо реальний сервіс
  baseUrl: 'https://fsapi.cashalot.org.ua',
  keyPath: 'assets/keys/Key-6.dat',
  certPath: 'assets/keys/Cert.crt',
  keyPassword: 'ваш_пароль_від_ключа',
  defaultPrroFiscalNum: '4000000001',
);
```

## Крок 3: Тестування

Після налаштування всі операції з CashalotService будуть використовувати реальний API:

- `openShift()` - відкриття зміни
- `registerSale()` - реєстрація продажу
- `serviceDeposit()` - службове внесення
- `serviceIssue()` - службова видача
- `closeShift()` - закриття зміни

## Безпека

⚠️ **ВАЖЛИВО:** Не комітьте файли ключів в Git!

Додайте в `.gitignore`:
```
assets/keys/*.dat
assets/keys/*.crt
assets/keys/*.pem
```

## Формат ключів

- **Key-6.dat** - приватний ключ (Base64)
- **Cert.crt** - сертифікат (Base64)
- **Password** - пароль від приватного ключа

## Структура запиту

Кожен запит до API містить:

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

