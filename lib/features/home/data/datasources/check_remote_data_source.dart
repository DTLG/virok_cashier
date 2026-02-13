import 'package:supabase_flutter/supabase_flutter.dart';

class CheckRemoteDataSource {
  final SupabaseClient client;

  CheckRemoteDataSource(this.client);

  Future<int> createCheck({
    required String seller,

    double? amount,
    String? paymentForm,
    String? status, 
    String? rrn,
      
  }) async {
    final nowUtc = DateTime.now().toIso8601String();
    final row = await client
        .schema('virok_cashier')
        .from('kkm_checks')
        .insert({
          'document_date': nowUtc,
          'kkm_cash_register': seller,
          'document_type': 'Чек ККМ',
          if (status != null) 'status': status,
          'kkm_check_number': _generateCheckNumber(),
          if (amount != null) 'amount': amount,
          if (paymentForm != null) 'payment_form': paymentForm,
          "RRN": rrn,
        })
        .select()
        .single();
    return row['id'] as int;
  }

  String _generateCheckNumber() {
    return (DateTime.now().millisecondsSinceEpoch).toString();
  }

  Future<void> insertCheckItems(int checkId, List<Map<String, dynamic>> items) {
    final rows = items.map((it) => {...it, 'check_id': checkId}).toList();
    return client.schema('virok_cashier').from('kkm_check_items').insert(rows);
  }

  /// Пошук чека за фіскальним номером (document_number)
  Future<Map<String, dynamic>?> getCheckByFiscalNumber(
    String fiscalNumber,
  ) async {
    final rows = await client
        .schema('virok_cashier')
        .from('kkm_checks')
        .select()
        .eq('document_number', fiscalNumber)
        .limit(1);

    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Список товарів чека за його ID (check_id)
  Future<List<Map<String, dynamic>>> getCheckItems(int checkId) async {
    final rows = await client
        .schema('virok_cashier')
        .from('kkm_check_items')
        .select()
        .eq('check_id', checkId);

    return rows.cast<Map<String, dynamic>>();
  }
}
