# Конфігурація Cashalot

## Безпека

⚠️ **ВАЖЛИВО:** Файл `cashalot_config.dart` містить чутливі дані (паролі, ключі) і **НЕ КОМІТИТЬТЕ ЙОГО В GIT!**

Файл вже додано в `.gitignore` для захисту.

## Налаштування

### 1. Створення конфігураційного файлу

Якщо файл `cashalot_config.dart` ще не існує:

1. Скопіюйте приклад:
   ```bash
   cp lib/core/config/cashalot_config.example.dart lib/core/config/cashalot_config.dart
   ```

2. Відкрийте `lib/core/config/cashalot_config.dart` і заповніть реальними значеннями:
   ```dart
   class CashalotConfig {
     static const String baseUrl = 'https://fsapi.cashalot.org.ua';
     static const String keyPath = 'assets/cashalot_keys/Key-6.dat';
     static const String certPath = 'assets/cashalot_keys/Cert.crt';
     static const String keyPassword = 'ваш_реальний_пароль'; // ⚠️ НЕ КОМІТЬТЕ!
     static const String defaultPrroFiscalNum = '4000000001';
     static const bool useReal = true;
   }
   ```

### 2. Додавання ключів

Покладіть файли ключів в одну з папок:
- `assets/cashalot_keys/` (рекомендовано)
- `assets/keys/`

Обидві папки додано в `.gitignore`.

### 3. Перевірка .gitignore

Переконайтеся, що в `.gitignore` є такі правила:

```
# Cashalot keys and certificates
assets/cashalot_keys/
assets/keys/
assets/**/*.dat
assets/**/*.crt
assets/**/*.pem
assets/**/*.key
assets/**/*.jks
assets/**/*.p12
assets/**/*.pfx

# Configuration files with sensitive data
lib/core/config/cashalot_config.dart
```

## Використання

Конфігурація автоматично використовується в `app_initialization_service.dart`:

```dart
setupCashalotInjection(
  useReal: CashalotConfig.useReal,
  baseUrl: CashalotConfig.baseUrl,
  keyPath: CashalotConfig.keyPath,
  certPath: CashalotConfig.certPath,
  keyPassword: CashalotConfig.keyPassword,
  defaultPrroFiscalNum: CashalotConfig.defaultPrroFiscalNum,
);
```

## Перемикання між Mock та Real

Для розробки використовуйте Mock:

```dart
static const bool useReal = false;
```

Для продакшну використовуйте Real:

```dart
static const bool useReal = true;
```

## Альтернативні методи зберігання паролів

Якщо потрібна додаткова безпека, можна використовувати:

1. **Environment Variables** (через `flutter_dotenv`):
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   static String get keyPassword => dotenv.env['CASHALOT_KEY_PASSWORD'] ?? '';
   ```

2. **Secure Storage** (через `flutter_secure_storage`):
   ```dart
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';
   
   final storage = FlutterSecureStorage();
   static Future<String> get keyPassword async => 
     await storage.read(key: 'cashalot_key_password') ?? '';
   ```

3. **Build-time configuration** (через `--dart-define`):
   ```dart
   static const String keyPassword = String.fromEnvironment(
     'CASHALOT_KEY_PASSWORD',
     defaultValue: '',
   );
   ```
   
   Запуск:
   ```bash
   flutter run --dart-define=CASHALOT_KEY_PASSWORD=ваш_пароль
   ```

## Перевірка безпеки

Перед комітом переконайтеся:

1. ✅ Файл `cashalot_config.dart` не в Git:
   ```bash
   git status lib/core/config/cashalot_config.dart
   # Має показати "untracked" або не показувати файл
   ```

2. ✅ Ключі не в Git:
   ```bash
   git ls-files assets/cashalot_keys/
   git ls-files assets/keys/
   # Має бути порожньо
   ```

3. ✅ .gitignore працює:
   ```bash
   git check-ignore -v assets/cashalot_keys/Key-6.dat
   # Має показати правило з .gitignore
   ```

