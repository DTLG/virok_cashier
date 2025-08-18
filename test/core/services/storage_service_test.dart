import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/services/storage_service.dart';

void main() {
  late StorageService storageService;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
  });

  group('StorageService', () {
    test('should save user credentials', () async {
      // arrange
      const email = 'test@example.com';
      const password = 'password123';

      // act
      await storageService.saveUserCredentials(email, password);

      // assert
      final savedEmail = await storageService.getUserEmail();
      final savedPassword = await storageService.getUserPassword();
      final isLoggedIn = await storageService.isUserLoggedIn();

      expect(savedEmail, equals(email));
      expect(savedPassword, equals(password));
      expect(isLoggedIn, isTrue);
    });

    test('should return null for email when not saved', () async {
      // act
      final email = await storageService.getUserEmail();

      // assert
      expect(email, isNull);
    });

    test('should return null for password when not saved', () async {
      // act
      final password = await storageService.getUserPassword();

      // assert
      expect(password, isNull);
    });

    test('should return false for isUserLoggedIn when not logged in', () async {
      // act
      final isLoggedIn = await storageService.isUserLoggedIn();

      // assert
      expect(isLoggedIn, isFalse);
    });

    test('should clear user credentials', () async {
      // arrange
      const email = 'test@example.com';
      const password = 'password123';
      await storageService.saveUserCredentials(email, password);

      // act
      await storageService.clearUserCredentials();

      // assert
      final savedEmail = await storageService.getUserEmail();
      final savedPassword = await storageService.getUserPassword();
      final isLoggedIn = await storageService.isUserLoggedIn();

      expect(savedEmail, isNull);
      expect(savedPassword, isNull);
      expect(isLoggedIn, isFalse);
    });
  });
}
