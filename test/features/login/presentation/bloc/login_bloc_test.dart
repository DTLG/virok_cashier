import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import '../../../../../lib/core/error/failures.dart';
import '../../../../../lib/core/services/storage_service.dart';
import '../../../../../lib/features/login/domain/entities/user_data.dart';
import '../../../../../lib/features/login/domain/usecases/login_usecase.dart';
import '../../../../../lib/features/login/presentation/bloc/login_bloc.dart';
import '../../../../../lib/features/login/presentation/bloc/login_event.dart';
import '../../../../../lib/features/login/presentation/bloc/login_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockStorageService extends Mock implements StorageService {}

void main() {
  late LoginBloc loginBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockStorageService mockStorageService;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockStorageService = MockStorageService();
    loginBloc = LoginBloc(
      loginUseCase: mockLoginUseCase,
      storageService: mockStorageService,
    );
  });

  tearDown(() {
    loginBloc.close();
  });

  test('initial state should be LoginInitial', () {
    expect(loginBloc.state, equals(LoginInitial()));
  });

  group('LoginSubmitted', () {
    const email = 'test@example.com';
    const password = 'password123';
    final userData = UserData(
      id: '1',
      name: 'Test User',
      email: email,
      password: password,
    );

    test(
      'should emit [LoginLoading, LoginSuccess] when login is successful',
      () async {
        // arrange
        when(
          () => mockLoginUseCase(email, password),
        ).thenAnswer((_) async => Right(userData));
        when(
          () => mockStorageService.saveUserCredentials(email, password),
        ).thenAnswer((_) async {});

        // assert later
        final expected = [LoginLoading(), LoginSuccess(userData)];
        expectLater(loginBloc.stream, emitsInOrder(expected));

        // act
        loginBloc.add(LoginSubmitted(email: email, password: password));
      },
    );

    test('should save user credentials when login is successful', () async {
      // arrange
      when(
        () => mockLoginUseCase(email, password),
      ).thenAnswer((_) async => Right(userData));
      when(
        () => mockStorageService.saveUserCredentials(email, password),
      ).thenAnswer((_) async {});

      // act
      loginBloc.add(LoginSubmitted(email: email, password: password));

      // assert
      await untilCalled(
        () => mockStorageService.saveUserCredentials(email, password),
      );
      verify(
        () => mockStorageService.saveUserCredentials(email, password),
      ).called(1);
    });

    test('should emit [LoginLoading, LoginFailure] when login fails', () async {
      // arrange
      const failureMessage = 'Server error';
      when(
        () => mockLoginUseCase(email, password),
      ).thenAnswer((_) async => Left(ServerFailure(failureMessage)));

      // assert later
      final expected = [LoginLoading(), LoginFailure(failureMessage)];
      expectLater(loginBloc.stream, emitsInOrder(expected));

      // act
      loginBloc.add(LoginSubmitted(email: email, password: password));
    });

    test('should not save credentials when login fails', () async {
      // arrange
      const failureMessage = 'Server error';
      when(
        () => mockLoginUseCase(email, password),
      ).thenAnswer((_) async => Left(ServerFailure(failureMessage)));

      // act
      loginBloc.add(LoginSubmitted(email: email, password: password));

      // assert
      await untilCalled(() => mockLoginUseCase(email, password));
      verifyNever(() => mockStorageService.saveUserCredentials(any(), any()));
    });
  });
}
