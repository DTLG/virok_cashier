import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:cash_register/features/login/domain/usecases/login_usecase.dart';
import 'package:cash_register/features/login/data/repositories/auth_repository_impl.dart';
import 'package:cash_register/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:cash_register/features/login/domain/entities/user_data.dart';
import 'package:cash_register/core/error/failures.dart';

void main() {
  late LoginUseCase loginUseCase;
  late AuthRepositoryImpl authRepository;
  late AuthRemoteDataSourceImpl authRemoteDataSource;

  setUp(() {
    authRemoteDataSource = AuthRemoteDataSourceImpl();
    authRepository = AuthRepositoryImpl(remoteDataSource: authRemoteDataSource);
    loginUseCase = LoginUseCase(repository: authRepository);
  });

  group('Login Integration Tests', () {
    group('successful login flow', () {
      test(
        'should successfully login with correct admin credentials',
        () async {
          // arrange
          const email = 'admin';
          const password = 'admin';

          // act
          final result = await loginUseCase(email, password);

          // assert
          expect(result.isRight(), true);
          result.fold((failure) => fail('Should not return failure'), (user) {
            expect(user.id, '1');
            expect(user.name, 'Адміністратор');
            expect(user.email, 'admin');
            expect(user.password, 'admin');
          });
        },
      );
    });

    group('failed login scenarios', () {
      test('should return failure when email is empty', () async {
        // arrange
        const email = '';
        const password = 'admin';

        // act
        final result = await loginUseCase(email, password);

        // assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(
            (failure as ServerFailure).message,
            'Email та пароль не можуть бути пустими',
          );
        }, (user) => fail('Should not return user'));
      });

      test('should return failure when password is empty', () async {
        // arrange
        const email = 'admin';
        const password = '';

        // act
        final result = await loginUseCase(email, password);

        // assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(
            (failure as ServerFailure).message,
            'Email та пароль не можуть бути пустими',
          );
        }, (user) => fail('Should not return user'));
      });

      test(
        'should return failure when both email and password are empty',
        () async {
          // arrange
          const email = '';
          const password = '';

          // act
          final result = await loginUseCase(email, password);

          // assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              (failure as ServerFailure).message,
              'Email та пароль не можуть бути пустими',
            );
          }, (user) => fail('Should not return user'));
        },
      );

      test(
        'should return failure when wrong credentials are provided',
        () async {
          // arrange
          const email = 'wrong@email.com';
          const password = 'wrongpassword';

          // act
          final result = await loginUseCase(email, password);

          // assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              (failure as ServerFailure).message,
              contains('Невірні облікові дані'),
            );
          }, (user) => fail('Should not return user'));
        },
      );

      test(
        'should return failure when wrong email but correct password',
        () async {
          // arrange
          const email = 'wrong@email.com';
          const password = 'admin';

          // act
          final result = await loginUseCase(email, password);

          // assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              (failure as ServerFailure).message,
              contains('Невірні облікові дані'),
            );
          }, (user) => fail('Should not return user'));
        },
      );

      test(
        'should return failure when correct email but wrong password',
        () async {
          // arrange
          const email = 'admin';
          const password = 'wrongpassword';

          // act
          final result = await loginUseCase(email, password);

          // assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              (failure as ServerFailure).message,
              contains('Невірні облікові дані'),
            );
          }, (user) => fail('Should not return user'));
        },
      );
    });

    group('performance tests', () {
      test('should complete login within reasonable time', () async {
        // arrange
        const email = 'admin';
        const password = 'admin';

        // act
        final stopwatch = Stopwatch()..start();
        final result = await loginUseCase(email, password);
        stopwatch.stop();

        // assert
        expect(stopwatch.elapsed.inSeconds, lessThan(3));
        expect(result.isRight(), true);
      });
    });

    group('data consistency tests', () {
      test('should return consistent user data for same credentials', () async {
        // arrange
        const email = 'admin';
        const password = 'admin';

        // act
        final result1 = await loginUseCase(email, password);
        final result2 = await loginUseCase(email, password);

        // assert
        expect(result1, result2);
        expect(result1.isRight(), true);
        expect(result2.isRight(), true);
      });
    });
  });
}
