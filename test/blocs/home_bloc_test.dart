import 'package:flutter_test/flutter_test.dart';
import 'package:cash_register/features/home/presentation/bloc/home_bloc.dart';
import 'package:cash_register/core/models/x_report_data.dart';

// ============================================================================
// Тести HomeViewState та CartItem (не потребують зовнішніх залежностей)
// ============================================================================

void main() {
  // ==========================================================================
  // Тести HomeViewState
  // ==========================================================================
  group('HomeViewState Tests', () {
    test('початковий стан має правильні значення за замовчуванням', () {
      const state = HomeViewState();

      expect(state.status, equals(HomeStatus.initial));
      expect(state.user, isNull);
      expect(state.isSidebarCollapsed, isFalse);
      expect(state.openedShiftAt, isNull);
      expect(state.shiftChecked, isFalse);
      expect(state.cart, isEmpty);
      expect(state.paymentForm, equals('Готівка'));
      expect(state.errorMessage, isEmpty);
      expect(state.searchResults, isEmpty);
      expect(state.currentPage, equals('/menu'));
    });

    test('copyWith змінює тільки вказані поля', () {
      const initialState = HomeViewState();

      final newState = initialState.copyWith(
        status: HomeStatus.loggedIn,
        paymentForm: 'Картка',
      );

      expect(newState.status, equals(HomeStatus.loggedIn));
      expect(newState.paymentForm, equals('Картка'));
      // Інші поля залишаються без змін
      expect(newState.cart, isEmpty);
      expect(newState.currentPage, equals('/menu'));
    });

    test('copyWith з clearOpenedShiftAt очищає openedShiftAt', () {
      final stateWithShift = HomeViewState(
        openedShiftAt: DateTime(2026, 2, 12, 10, 0),
      );

      final clearedState = stateWithShift.copyWith(clearOpenedShiftAt: true);

      expect(clearedState.openedShiftAt, isNull);
    });

    test('copyWith з clearXReportData очищає xReportData', () {
      final stateWithReport = HomeViewState(
        xReportData: XReportData(visualization: 'Test'),
      );

      final clearedState = stateWithReport.copyWith(clearXReportData: true);

      expect(clearedState.xReportData, isNull);
    });

    test('props містить всі поля для порівняння', () {
      const state1 = HomeViewState(paymentForm: 'Готівка');
      const state2 = HomeViewState(paymentForm: 'Готівка');
      const state3 = HomeViewState(paymentForm: 'Картка');

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });

  // ==========================================================================
  // Тести CartItem
  // ==========================================================================
  group('CartItem Tests', () {
    test('створення CartItem з правильними значеннями', () {
      final item = CartItem(
        guid: 'test-guid',
        name: 'Тестовий товар',
        article: 'ART001',
        price: 100.0,
        quantity: 2,
      );

      expect(item.guid, equals('test-guid'));
      expect(item.name, equals('Тестовий товар'));
      expect(item.article, equals('ART001'));
      expect(item.price, equals(100.0));
      expect(item.quantity, equals(2));
    });

    test('CartItem за замовчуванням має quantity = 1', () {
      final item = CartItem(
        guid: 'test-guid',
        name: 'Товар',
        article: 'ART',
        price: 50.0,
      );

      expect(item.quantity, equals(1));
    });

    test('copyWith змінює тільки вказані поля', () {
      final item = CartItem(
        guid: 'test-guid',
        name: 'Товар',
        article: 'ART',
        price: 50.0,
        quantity: 1,
      );

      final updatedItem = item.copyWith(quantity: 5);

      expect(updatedItem.quantity, equals(5));
      expect(updatedItem.guid, equals('test-guid'));
      expect(updatedItem.price, equals(50.0));
    });

    test('два CartItem з однаковими полями рівні', () {
      final item1 = CartItem(
        guid: 'guid',
        name: 'Name',
        article: 'Art',
        price: 10.0,
        quantity: 1,
      );

      final item2 = CartItem(
        guid: 'guid',
        name: 'Name',
        article: 'Art',
        price: 10.0,
        quantity: 1,
      );

      expect(item1, equals(item2));
    });
  });

  // ==========================================================================
  // Тести HomeStatus enum
  // ==========================================================================
  group('HomeStatus Tests', () {
    test('всі статуси існують', () {
      expect(HomeStatus.values, contains(HomeStatus.initial));
      expect(HomeStatus.values, contains(HomeStatus.loading));
      expect(HomeStatus.values, contains(HomeStatus.loggedIn));
      expect(HomeStatus.values, contains(HomeStatus.error));
      expect(HomeStatus.values, contains(HomeStatus.checkedOut));
      expect(HomeStatus.values, contains(HomeStatus.returnLoading));
      expect(HomeStatus.values, contains(HomeStatus.returnSuccess));
      expect(HomeStatus.values, contains(HomeStatus.returnError));
    });
  });

  // ==========================================================================
  // Тести розрахунків корзини
  // ==========================================================================
  group('Cart Calculations', () {
    test('загальна сума корзини рахується правильно', () {
      final cart = [
        CartItem(guid: '1', name: 'A', article: 'A', price: 100.0, quantity: 2),
        CartItem(guid: '2', name: 'B', article: 'B', price: 50.0, quantity: 3),
      ];

      final total = cart.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      expect(total, equals(350.0)); // 100*2 + 50*3 = 200 + 150 = 350
    });

    test('кількість товарів в корзині рахується правильно', () {
      final cart = [
        CartItem(guid: '1', name: 'A', article: 'A', price: 100.0, quantity: 2),
        CartItem(guid: '2', name: 'B', article: 'B', price: 50.0, quantity: 3),
      ];

      final totalItems = cart.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      expect(totalItems, equals(5));
    });
  });
}
