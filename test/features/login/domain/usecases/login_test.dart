import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cash_register/features/login/domain/repositories/auth_repository.dart';
import 'package:cash_register/features/login/domain/usecases/login_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:cash_register/features/login/domain/entities/user_data.dart';
import 'package:cash_register/core/error/failures.dart';
import '../../../../helpers/test_helpers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginUseCase loginUseCase;

  setUpAll(() {
    TestHelpers.registerFallbackValues();
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(repository: mockAuthRepository);
  });

  group('LoginUseCase', () {
    group('email validation', () {
      test('should return failure when email format is invalid', () async {
        // arrange
        const invalidEmail = 'invalid-email';
        const password = 'password123';

        // act
        final result = await loginUseCase(invalidEmail, password);

        // assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Невірний формат email');
        }, (user) => fail('Should not return user'));
        verifyNever(() => mockAuthRepository.login(any(), any()));
      });

      test('should return failure when email is empty', () async {
        // arrange
        const emptyEmail = '';
        const password = 'password123';

        // act
        final result = await loginUseCase(emptyEmail, password);

        // assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, 'Невірний формат email');
        }, (user) => fail('Should not return user'));
        verifyNever(() => mockAuthRepository.login(any(), any()));
      });

      test('should accept valid email format', () async {
        // arrange
        const validEmail = 'test@example.com';
        const password = 'password123';
        const userData = UserData(
          id: '1',
          name: 'Test User',
          email: validEmail,
          password: password,
        );

        when(
          () => mockAuthRepository.login(validEmail, password),
        ).thenAnswer((_) async => Right(userData));

        // act
        final result = await loginUseCase(validEmail, password);

        // assert
        expect(result.isRight(), true);
        verify(() => mockAuthRepository.login(validEmail, password)).called(1);
      });
    });

    group('successful login', () {
      test('should return user data when login is successful', () async {
        // arrange
        when(
          () => mockAuthRepository.login(
            TestHelpers.validEmail,
            TestHelpers.validPassword,
          ),
        ).thenAnswer((_) async => Right(TestHelpers.testUser));

        // act
        final result = await loginUseCase(
          TestHelpers.validEmail,
          TestHelpers.validPassword,
        );

        // assert
        expect(result, Right(TestHelpers.testUser));
        verify(
          () => mockAuthRepository.login(
            TestHelpers.validEmail,
            TestHelpers.validPassword,
          ),
        ).called(1);
      });
    });

    group('failed login scenarios', () {
      test('should return server failure when login fails', () async {
        // arrange
        when(
          () => mockAuthRepository.login(
            TestHelpers.validEmail,
            TestHelpers.validPassword,
          ),
        ).thenAnswer((_) async => Left(TestHelpers.serverFailure));

        // act
        final result = await loginUseCase(
          TestHelpers.validEmail,
          TestHelpers.validPassword,
        );

        // assert
        expect(result, Left(TestHelpers.serverFailure));
        verify(
          () => mockAuthRepository.login(
            TestHelpers.validEmail,
            TestHelpers.validPassword,
          ),
        ).called(1);
      });

      test('should handle weak password', () async {
        // arrange
        const weakPasswordFailure = ServerFailure('Password too weak');
        when(
          () => mockAuthRepository.login(
            TestHelpers.validEmail,
            TestHelpers.weakPassword,
          ),
        ).thenAnswer((_) async => Left(weakPasswordFailure));

        // act
        final result = await loginUseCase(
          TestHelpers.validEmail,
          TestHelpers.weakPassword,
        );

        // assert
        expect(result, Left(weakPasswordFailure));
        verify(
          () => mockAuthRepository.login(
            TestHelpers.validEmail,
            TestHelpers.weakPassword,
          ),
        ).called(1);
      });
    });

    group('edge cases', () {
      test('should handle very long email', () async {
        // arrange
        const longEmail = 'verylongemailaddress@verylongdomainname.com';
        const longEmailFailure = ServerFailure('Email too long');
        when(
          () => mockAuthRepository.login(longEmail, TestHelpers.validPassword),
        ).thenAnswer((_) async => Left(longEmailFailure));

        // act
        final result = await loginUseCase(longEmail, TestHelpers.validPassword);

        // assert
        expect(result, Left(longEmailFailure));
        verify(
          () => mockAuthRepository.login(longEmail, TestHelpers.validPassword),
        ).called(1);
      });

      test('should handle special characters in password', () async {
        // arrange
        const specialPassword = 'p@ssw0rd!@#';
        const specialPasswordFailure = ServerFailure(
          'Password contains invalid characters',
        );
        when(
          () =>
              mockAuthRepository.login(TestHelpers.validEmail, specialPassword),
        ).thenAnswer((_) async => Left(specialPasswordFailure));

        // act
        final result = await loginUseCase(
          TestHelpers.validEmail,
          specialPassword,
        );

        // assert
        expect(result, Left(specialPasswordFailure));
        verify(
          () =>
              mockAuthRepository.login(TestHelpers.validEmail, specialPassword),
        ).called(1);
      });
    });
  });
}
