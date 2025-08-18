import 'package:mocktail/mocktail.dart';
import 'package:cash_register/features/login/domain/entities/user_data.dart';
import 'package:cash_register/core/error/failures.dart';

/// Test helpers for common test data and utilities
class TestHelpers {
  static const String validEmail = 'test@example.com';
  static const String validPassword = 'password123';
  static const String invalidEmail = 'invalid-email';
  static const String weakPassword = '123';
  static const String emptyString = '';

  static const UserData testUser = UserData(
    id: '1',
    name: 'Test User',
    email: validEmail,
    password: validPassword,
  );

  static const ServerFailure serverFailure = ServerFailure(
    'Server error occurred',
  );
  static const ServerFailure invalidCredentialsFailure = ServerFailure(
    'Invalid credentials',
  );
  static const ServerFailure networkFailure = ServerFailure('Network error');

  /// Register common fallback values for mocktail
  static void registerFallbackValues() {
    registerFallbackValue(
      const UserData(id: '', name: '', email: '', password: ''),
    );
  }

  /// Create a test user with custom data
  static UserData createTestUser({
    String id = '1',
    String name = 'Test User',
    String email = validEmail,
    String password = validPassword,
  }) {
    return UserData(id: id, name: name, email: email, password: password);
  }

  /// Create a server failure with custom message
  static ServerFailure createServerFailure([String message = 'Server error']) {
    return ServerFailure(message);
  }
}
