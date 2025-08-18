# Тестування в Cash Register App

Цей документ пояснює різні типи тестів, які використовуються в проекті, та їх призначення.

## Типи тестів

### 1. Unit тести (Мок тести)
**Розташування:** `test/features/login/domain/usecases/login_test.dart`

**Призначення:** Тестують логіку взаємодії між компонентами без реальних залежностей.

**Що тестують:**
- Правильність виклику методів репозиторію
- Обробку результатів від репозиторію
- Валідацію вхідних даних
- Логіку бізнес-правил

**Переваги:**
- Швидкі виконання
- Ізольованість
- Легке налагодження

**Недоліки:**
- Не тестують реальну функціональність
- Не перевіряють інтеграцію між компонентами

### 2. Unit тести (Реальна логіка)
**Розташування:** 
- `test/features/login/data/repositories/auth_repository_impl_test.dart`
- `test/features/login/data/datasources/auth_remote_data_source_test.dart`

**Призначення:** Тестують реальну логіку конкретних класів.

**Що тестують:**
- Валідацію email/пароля в репозиторії
- Логіку аутентифікації в DataSource
- Обробку винятків
- Продуктивність

**Переваги:**
- Тестують реальну логіку
- Перевіряють бізнес-правила
- Швидкі виконання

### 3. Інтеграційні тести
**Розташування:** `test/features/login/integration/login_integration_test.dart`

**Призначення:** Тестують повний flow від UseCase до DataSource.

**Що тестують:**
- Повний процес логіну
- Інтеграцію між всіма компонентами
- Продуктивність end-to-end
- Консистентність даних

**Переваги:**
- Тестують реальну функціональність
- Перевіряють інтеграцію компонентів
- Найближчі до реального використання

**Недоліки:**
- Повільніші виконання
- Складніше налагодження

## Як запускати тести

### Всі тести
```bash
flutter test
```

### Конкретний файл
```bash
flutter test test/features/login/domain/usecases/login_test.dart
```

### Інтеграційні тести
```bash
flutter test test/features/login/integration/
```

### Unit тести
```bash
flutter test test/features/login/data/
```

## Структура тестів

### Arrange-Act-Assert Pattern
Всі тести слідують патерну AAA:

```dart
test('should do something', () async {
  // Arrange - підготовка даних
  const email = 'test@example.com';
  const password = 'password123';
  
  // Act - виконання дії
  final result = await loginUseCase(email, password);
  
  // Assert - перевірка результату
  expect(result.isRight(), true);
});
```

### Групування тестів
Тести групуються за функціональністю:

```dart
group('LoginUseCase', () {
  group('email validation', () {
    // тести валідації email
  });
  
  group('successful login', () {
    // тести успішного логіну
  });
  
  group('failed login scenarios', () {
    // тести невдалих сценаріїв
  });
});
```

## Тест хелпери

**Розташування:** `test/helpers/test_helpers.dart`

Містить спільні дані та утиліти для тестів:
- Константи для тестових даних
- Методи створення тестових об'єктів
- Реєстрація fallback значень для mocktail

## Рекомендації

1. **Почніть з unit тестів** - вони швидкі та допомагають знайти помилки в логіці
2. **Додайте інтеграційні тести** для критичних flow
3. **Використовуйте тест хелпери** для уникнення дублювання коду
4. **Групуйте тести** за функціональністю
5. **Пишіть описові назви тестів** - вони служать документацією

## Приклади реальних сценаріїв

### Успішний логін
```dart
test('should successfully login with correct admin credentials', () async {
  const email = 'admin';
  const password = 'admin';
  
  final result = await loginUseCase(email, password);
  
  expect(result.isRight(), true);
  result.fold(
    (failure) => fail('Should not return failure'),
    (user) {
      expect(user.id, '1');
      expect(user.name, 'Адміністратор');
    },
  );
});
```

### Невдалий логін
```dart
test('should return failure when wrong credentials are provided', () async {
  const email = 'wrong@email.com';
  const password = 'wrongpassword';
  
  final result = await loginUseCase(email, password);
  
  expect(result.isLeft(), true);
  result.fold(
    (failure) {
      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).message, contains('Невірні облікові дані'));
    },
    (user) => fail('Should not return user'),
  );
});
```

