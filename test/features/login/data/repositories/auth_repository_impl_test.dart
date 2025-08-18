import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:cash_register/features/login/data/repositories/auth_repository_impl.dart';
import 'package:cash_register/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:cash_register/features/login/data/models/user_model.dart';
import 'package:cash_register/core/error/failures.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('AuthRepositoryImpl', () {
    group('login', () {
      test('should return user data when login is successful', () async {
        // arrange
        const email = 'admin';
        const password = 'admin';
        const userModel = UserModel(
          id: '1',
          name: 'Адміністратор',
          email: 'admin',
          password: 'admin',
        );

        when(
          () => mockRemoteDataSource.login(email, password),
        ).thenAnswer((_) async => userModel);

        // act
        final result = await repository.login(email, password);

        // assert
        expect(result, Right(userModel));
        verify(() => mockRemoteDataSource.login(email, password)).called(1);
      });

      test(
        'should return failure when both email and password are empty',
        () async {
          // arrange
          const email = '';
          const password = '';

          // act
          final result = await repository.login(email, password);

          // assert
          expect(
            result,
            const Left(ServerFailure('Email та пароль не можуть бути пустими')),
          );
          verifyNever(() => mockRemoteDataSource.login(any(), any()));
        },
      );

      test(
        'should return failure when email is empty but password is not',
        () async {
          // arrange
          const email = '';
          const password = 'admin';

          // act
          final result = await repository.login(email, password);

          // assert
          expect(
            result,
            const Left(ServerFailure('Email та пароль не можуть бути пустими')),
          );
          verifyNever(() => mockRemoteDataSource.login(any(), any()));
        },
      );

      test(
        'should return failure when password is empty but email is not',
        () async {
          // arrange
          const email = 'admin';
          const password = '';

          // act
          final result = await repository.login(email, password);

          // assert
          expect(
            result,
            const Left(ServerFailure('Email та пароль не можуть бути пустими')),
          );
          verifyNever(() => mockRemoteDataSource.login(any(), any()));
        },
      );

      test(
        'should return failure when remote data source throws exception',
        () async {
          // arrange
          const email = 'wrong@email.com';
          const password = 'wrongpassword';

          when(
            () => mockRemoteDataSource.login(email, password),
          ).thenThrow(Exception('Невірні облікові дані'));

          // act
          final result = await repository.login(email, password);

          // assert
          expect(
            result,
            const Left(ServerFailure('Exception: Невірні облікові дані')),
          );
          verify(() => mockRemoteDataSource.login(email, password)).called(1);
        },
      );

      test(
        'should return failure when remote data source throws network exception',
        () async {
          // arrange
          const email = 'admin';
          const password = 'admin';

          when(
            () => mockRemoteDataSource.login(email, password),
          ).thenThrow(Exception('Network error'));

          // act
          final result = await repository.login(email, password);

          // assert
          expect(result, const Left(ServerFailure('Exception: Network error')));
          verify(() => mockRemoteDataSource.login(email, password)).called(1);
        },
      );
    });
  });
}
