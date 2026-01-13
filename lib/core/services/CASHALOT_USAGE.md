# Використання CashalotService в проекті

## Інтеграція завершена

CashalotService інтегровано в проект через Dependency Injection та використовується в HomeBloc.

## Доступні методи

### 1. Реєстрація продажу (Checkout)

При натисканні кнопки "Провести чек" автоматично викликається `CashalotService.registerSale()`:

```dart
// В HomeBloc автоматично викликається при CheckoutEvent
context.read<HomeBloc>().add(const CheckoutEvent());
```

### 2. Відкриття зміни

```dart
// Відкрити зміну для першого доступного ПРРО
context.read<HomeBloc>().add(const OpenCashalotShift());

// Або вказати конкретний ПРРО
context.read<HomeBloc>().add(const OpenCashalotShift(prroFiscalNum: 4000000001));
```

### 3. Закриття зміни (Z-звіт)

```dart
// Закрити зміну для першого доступного ПРРО
context.read<HomeBloc>().add(const CloseCashalotShift());

// Або вказати конкретний ПРРО
context.read<HomeBloc>().add(const CloseCashalotShift(prroFiscalNum: 4000000001));
```

### 4. Службове внесення (розмін)

```dart
// Внести гроші в касу
context.read<HomeBloc>().add(const ServiceDepositEvent(amount: 1000.0));
```

### 5. Службова видача (інкасація)

```dart
// Забрати гроші з каси
context.read<HomeBloc>().add(const ServiceIssueEvent(amount: 5000.0));
```

## Приклад використання в UI

### Діалог відкриття зміни

```dart
ElevatedButton(
  onPressed: () {
    context.read<HomeBloc>().add(const OpenCashalotShift());
  },
  child: const Text('Відкрити зміну'),
)
```

### Діалог закриття зміни

```dart
ElevatedButton(
  onPressed: () {
    context.read<HomeBloc>().add(const CloseCashalotShift());
  },
  child: const Text('Закрити зміну (Z-звіт)'),
)
```

## Обробка результатів

Всі операції автоматично обробляються в HomeBloc:
- При успіху - статус змінюється на `HomeStatus.loggedIn`
- При помилці - статус змінюється на `HomeStatus.error` з повідомленням

Візуалізація чеків виводиться в консоль (для тестування).

## Заміна Mock на Real реалізацію

Коли буде готова реальна реалізація, достатньо змінити реєстрацію в `lib/core/di/cashalot_injection.dart`:

```dart
// Було:
_sl.registerLazySingleton<CashalotService>(
  () => MockCashalotService(),
);

// Стане:
_sl.registerLazySingleton<CashalotService>(
  () => RealCashalotService(
    apiKey: "...",
    pemKey: "...",
  ),
);
```

Весь інший код залишається без змін!

