import '../repositories/home_repository.dart';

class Checkout {
  final HomeRepository repository;
  Checkout(this.repository);
  Future<void> call() => repository.checkoutCurrentCart();
}
