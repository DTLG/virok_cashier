# Cash Register App

Flutter додаток для касового апарату з системою авторизації та збереженням даних користувача.

## Функціональність

### Авторизація та збереження даних
- **Збереження даних користувача**: Після успішного входу email та пароль зберігаються в SharedPreferences
- **Автоматична перевірка статусу**: При відкритті Home сторінки автоматично перевіряється чи користувач залогінений
- **Відновлення сесії**: Якщо користувач вже залогінений, створюється об'єкт UserData з збережених даних
- **Вихід з системи**: Кнопка logout очищає збережені дані та повертає до екрану входу

### Архітектура
- **Clean Architecture** з розділенням на слої (presentation, domain, data)
- **BLoC pattern** для управління станом
- **SharedPreferences** для збереження даних користувача
- **Dependency Injection** з get_it

### Структура проекту
```
lib/
├── core/
│   ├── services/
│   │   └── storage_service.dart      # Сервіс для роботи з SharedPreferences
│   └── error/
│       └── failures.dart
├── features/
│   ├── login/                        # Модуль авторизації
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── home/                         # Модуль головної сторінки
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── bloc/
│           │   ├── home_bloc.dart    # BLoC для управління станом Home
│           │   ├── home_event.dart   # Події Home
│           │   └── home_state.dart   # Стани Home
│           ├── pages/
│           │   └── home_page.dart    # Головна сторінка
│           └── widgets/
│               ├── login_required_widget.dart    # Екран входу
│               ├── home_loading_widget.dart      # Екран завантаження
│               └── cashier_header.dart           # Заголовок каси
```

## Використання

### Збереження даних користувача
```dart
// В LoginBloc після успішного входу
await storageService.saveUserCredentials(email, password);
```

### Перевірка статусу авторизації
```dart
// В HomeBloc при ініціалізації
final isLoggedIn = await storageService.isUserLoggedIn();
if (isLoggedIn) {
  final email = await storageService.getUserEmail();
  final password = await storageService.getUserPassword();
  // Створення UserData об'єкта
}
```

### Вихід з системи
```dart
// В HomeBloc при logout
await storageService.clearUserCredentials();
```

## Тестування

Проект включає unit тести для:
- `StorageService` - тестування збереження/отримання даних
- `LoginBloc` - тестування логіки авторизації
- `HomeBloc` - тестування перевірки статусу та logout

Запуск тестів:
```bash
flutter test
```

## Залежності

- `shared_preferences` - для збереження даних
- `flutter_bloc` - для управління станом
- `dartz` - для функціонального програмування
- `equatable` - для порівняння об'єктів
- `mocktail` - для моків в тестах
