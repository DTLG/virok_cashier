import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/storage/storage_service.dart';

class ShiftRemoteDataSource {
  final SupabaseClient client;

  ShiftRemoteDataSource(this.client);

  /// Returns latest shift row for today for current user, or null if none
  Future<Map<String, dynamic>?> getTodayLatestShift() async {
    // Use stored login (email) instead of Supabase auth user id
    final login = await StorageService().getUserEmail();
    if (login == null || login.isEmpty) return null;

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await client
        .schema('virok_cashier')
        .from('shifts')
        .select()
        .eq('user_id', login)
        .gte('opened_at', startOfDay.toIso8601String())
        .lt('opened_at', endOfDay.toIso8601String())
        .order('opened_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> getLastOpenedShiftBeforeToday() async {
    final login = await StorageService().getUserEmail();
    if (login == null || login.isEmpty) return null;

    // Межа "початок сьогодні" у локальному часі → в UTC
    final now = DateTime.now();
    final startOfTodayLocal = DateTime(now.year, now.month, now.day);
    final startOfToday = startOfTodayLocal.toIso8601String();

    final rows = await client
        .schema('virok_cashier')
        .from('shifts')
        .select()
        .eq('user_id', login)
        .lt('opened_at', startOfToday)
        .order('opened_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  /// Opens a new shift with the specified opening amount
  Future<Map<String, dynamic>> openShift(double openingAmount) async {
    final login = await StorageService().getUserEmail();
    if (login == null || login.isEmpty) {
      throw Exception('Не знайдено логін користувача');
    }

    if (openingAmount < 0) {
      throw Exception('Введіть коректну суму (не менше 0)');
    }

    final nowUtc = DateTime.now().toIso8601String();
    final result = await client
        .schema('virok_cashier')
        .from('shifts')
        .insert({
          'user_id': login,
          'opened_at': nowUtc,
          'opening_amount': openingAmount,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(result);
  }

  /// Gets the last opened shift for the current user
  Future<Map<String, dynamic>?> getLastOpenedShift() async {
    final login = await StorageService().getUserEmail();
    if (login == null || login.isEmpty) return null;

    final rows = await client
        .schema('virok_cashier')
        .from('shifts')
        .select()
        .eq('user_id', login)
        .isFilter('closed_at', null)
        .order('opened_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  /// Gets sales data for a shift period
  Future<Map<String, double>> getShiftSalesData(DateTime openedAt) async {
    final login = await StorageService().getUserEmail();
    if (login == null || login.isEmpty) {
      throw Exception('Не знайдено логін');
    }

    final from = openedAt.toIso8601String();
    final to = DateTime(
      openedAt.year,
      openedAt.month,
      openedAt.day,
      23,
      59,
      59,
    ).toIso8601String();

    final checkRows = await client
        .schema('virok_cashier')
        .from('kkm_checks')
        .select('payment_form, amount')
        .eq('kkm_cash_register', login)
        .eq('status', 'Чек пробитий')
        .gte('document_date', from)
        .lte('document_date', to);

    double salesCash = 0.0;
    double salesCashless = 0.0;

    for (final r in checkRows) {
      final amount = (r['amount'] as num?)?.toDouble() ?? 0.0;
      final form = (r['payment_form'] as String?) ?? '';

      if (form == 'Готівка') {
        salesCash += amount;
      } else if (form == 'Картка') {
        salesCashless += amount;
      }
    }

    return {'cash': salesCash, 'cashless': salesCashless};
  }

  /// Closes a shift with the specified closing amount and sales data
  Future<Map<String, dynamic>> closeShift({
    required int shiftId,
    required double closingAmount,
    required double salesAmountCash,
    required double salesAmountCashless,
  }) async {
    final result = await client
        .schema('virok_cashier')
        .from('shifts')
        .update({
          'closed_at': DateTime.now().toIso8601String(),
          'closing_amount': closingAmount,
          'sales_amount_cash': salesAmountCash,
          'sales_amount_cashless': salesAmountCashless,
        })
        .eq('id', shiftId)
        .select()
        .single();

    return Map<String, dynamic>.from(result);
  }
}
