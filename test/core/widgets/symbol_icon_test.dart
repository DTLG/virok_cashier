import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cash_register/core/widgets/symbol_icon.dart';

void main() {
  group('SymbolIcon', () {
    testWidgets('should display symbol correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SymbolIcon(symbol: '₴')),
        ),
      );

      expect(find.text('₴'), findsOneWidget);
    });

    testWidgets('should apply custom styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SymbolIcon(
              symbol: '₴',
              size: 32.0,
              color: Colors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('₴'));
      expect(textWidget.style?.fontSize, 32.0);
      expect(textWidget.style?.color, Colors.red);
      expect(textWidget.style?.fontWeight, FontWeight.w900);
    });

    testWidgets('should use default values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SymbolIcon(symbol: '₴')),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('₴'));
      expect(textWidget.style?.fontSize, 24.0);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
