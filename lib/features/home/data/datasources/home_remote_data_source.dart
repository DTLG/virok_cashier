import 'package:supabase_flutter/supabase_flutter.dart';

abstract class HomeRemoteDataSource {
  Future<DateTime?> getLastOpenedShift();
  Future<void> openTodayShift();
  Future<void> closePreviousShift();
  Future<void> checkoutCart();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient client;
  HomeRemoteDataSourceImpl(this.client);

  @override
  Future<void> checkoutCart() async {
    // TODO: implement actual checkout using existing CheckRemoteDataSource if needed
  }

  @override
  Future<void> closePreviousShift() async {
    // TODO: implement using a table/mutation
  }

  @override
  Future<DateTime?> getLastOpenedShift() async {
    // TODO: implement using shifts table
    return null;
  }

  @override
  Future<void> openTodayShift() async {
    // TODO: implement using shifts table
  }
}
