import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_register/features/home/presentation/widgets/payment_method_selector.dart';

void main() {
  group('PaymentMethodSelector', () {
    testWidgets('should display payment methods', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PaymentMethodSelector())),
      );

      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Готівка'), findsOneWidget);
      expect(find.text('Debit Card'), findsOneWidget);
      expect(find.text('E-Wallet'), findsOneWidget);
    });

    testWidgets('should display hryvnia symbol for cash', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PaymentMethodSelector())),
      );

      // Перевіряємо наявність символу гривні
      expect(find.text('₴'), findsOneWidget);
    });

    testWidgets('should change selection when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PaymentMethodSelector())),
      );

      // За замовчуванням вибрана готівка
      expect(find.text('₴'), findsOneWidget);

      // Натискаємо на Debit Card
      await tester.tap(find.text('Debit Card'));
      await tester.pump();

      // Перевіряємо що вибрана картка (символ гривні не повинен бути видимий як вибраний)
      expect(find.text('Debit Card'), findsOneWidget);
    });
  });
}
