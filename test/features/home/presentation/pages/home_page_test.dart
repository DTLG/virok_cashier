import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_register/features/home/presentation/pages/home_page.dart';

void main() {
  group('HomePage', () {
    testWidgets('should display all main sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      // Перевіряємо наявність основних елементів
      expect(find.text('Virok'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Cash Register #1'), findsOneWidget);
      expect(find.text('Leslie K.'), findsOneWidget);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.text('Place Order'), findsOneWidget);
    });

    testWidgets('should display navigation items', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      // Перевіряємо наявність пунктів навігації
      expect(find.text('Reservation'), findsOneWidget);
      expect(find.text('Table services'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Accounting'), findsOneWidget);
    });

    testWidgets('should display category grid', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      // Перевіряємо наявність категорій
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Soups'), findsOneWidget);
      expect(find.text('Pasta'), findsOneWidget);
      expect(find.text('Sushi'), findsOneWidget);
      expect(find.text('Main course'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
      expect(find.text('Drinks'), findsOneWidget);
      expect(find.text('Alcohol'), findsOneWidget);
    });
  });
}
