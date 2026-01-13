abstract class HomeRepository {
  Future<bool> isUserLoggedIn();
  Future<DateTime?> getLastOpenedShift();
  Future<void> openTodayShift();
  Future<void> closePreviousShift();
  Future<void> checkoutCurrentCart();
}
