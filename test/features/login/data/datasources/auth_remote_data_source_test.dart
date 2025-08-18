import 'package:flutter_test/flutter_test.dart';
import 'package:cash_register/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:cash_register/features/login/data/models/user_model.dart';

void main() {
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    dataSource = AuthRemoteDataSourceImpl();
  });

  group('AuthRemoteDataSourceImpl', () {
    group('login', () {
      test(
        'should return admin user when correct credentials are provided',
        () async {
          // arrange
          const email = 'admin';
          const password = 'admin';

          // act
          final result = await dataSource.login(email, password);

          // assert
          expect(
            result,
            const UserModel(
              id: '1',
              name: 'Адміністратор',
              email: 'admin',
              password: 'admin',
            ),
          );
        },
      );

      test('should throw exception when wrong email is provided', () async {
        // arrange
        const email = 'wrong@email.com';
        const password = 'admin';

        // act & assert
        expect(
          () => dataSource.login(email, password),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when wrong password is provided', () async {
        // arrange
        const email = 'admin';
        const password = 'wrongpassword';

        // act & assert
        expect(
          () => dataSource.login(email, password),
          throwsA(isA<Exception>()),
        );
      });

      test(
        'should throw exception when both email and password are wrong',
        () async {
          // arrange
          const email = 'wrong@email.com';
          const password = 'wrongpassword';

          // act & assert
          expect(
            () => dataSource.login(email, password),
            throwsA(isA<Exception>()),
          );
        },
      );

      test('should throw exception with correct error message', () async {
        // arrange
        const email = 'wrong@email.com';
        const password = 'wrongpassword';

        // act & assert
        expect(
          () => dataSource.login(email, password),
          throwsA(
            predicate((e) => e.toString().contains('Невірні облікові дані')),
          ),
        );
      });

      test(
        'should complete within reasonable time (less than 3 seconds)',
        () async {
          // arrange
          const email = 'admin';
          const password = 'admin';

          // act & assert
          final stopwatch = Stopwatch()..start();
          await dataSource.login(email, password);
          stopwatch.stop();

          expect(stopwatch.elapsed.inSeconds, lessThan(3));
        },
      );
    });
  });
}

