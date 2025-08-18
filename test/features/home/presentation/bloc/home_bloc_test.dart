import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../../lib/core/services/storage_service.dart';
import '../../../../../lib/features/login/domain/entities/user_data.dart';
import '../../../../../lib/features/home/presentation/bloc/home_bloc.dart';

class MockStorageService extends Mock implements StorageService {}

void main() {
  late HomeBloc homeBloc;
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
    homeBloc = HomeBloc(storageService: mockStorageService);
  });

  tearDown(() {
    homeBloc.close();
  });

  test('initial state should be HomeInitial', () {
    expect(homeBloc.state, equals(HomeInitial()));
  });

  group('CheckUserLoginStatus', () {
    test('should emit HomeLoggedIn when user is logged in', () async {
      // arrange
      const email = 'test@example.com';
      const password = 'password123';
      final userData = UserData(
        id: '1',
        name: 'test',
        email: email,
        password: password,
      );

      when(
        () => mockStorageService.isUserLoggedIn(),
      ).thenAnswer((_) async => true);
      when(
        () => mockStorageService.getUserEmail(),
      ).thenAnswer((_) async => email);
      when(
        () => mockStorageService.getUserPassword(),
      ).thenAnswer((_) async => password);

      // assert later
      final expected = [HomeLoading(), HomeLoggedIn(user: userData)];
      expectLater(homeBloc.stream, emitsInOrder(expected));

      // act
      homeBloc.add(const CheckUserLoginStatus());
    });

    test('should emit HomeInitial when user is not logged in', () async {
      // arrange
      when(
        () => mockStorageService.isUserLoggedIn(),
      ).thenAnswer((_) async => false);

      // assert later
      final expected = [HomeLoading(), HomeInitial()];
      expectLater(homeBloc.stream, emitsInOrder(expected));

      // act
      homeBloc.add(const CheckUserLoginStatus());
    });

    test(
      'should emit HomeInitial and clear credentials when data is corrupted',
      () async {
        // arrange
        when(
          () => mockStorageService.isUserLoggedIn(),
        ).thenAnswer((_) async => true);
        when(
          () => mockStorageService.getUserEmail(),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorageService.getUserPassword(),
        ).thenAnswer((_) async => null);
        when(
          () => mockStorageService.clearUserCredentials(),
        ).thenAnswer((_) async {});

        // assert later
        final expected = [HomeLoading(), HomeInitial()];
        expectLater(homeBloc.stream, emitsInOrder(expected));

        // act
        homeBloc.add(const CheckUserLoginStatus());

        // assert
        await untilCalled(() => mockStorageService.clearUserCredentials());
        verify(() => mockStorageService.clearUserCredentials()).called(1);
      },
    );
  });

  group('LogoutUser', () {
    test('should emit HomeInitial and clear credentials', () async {
      // arrange
      when(
        () => mockStorageService.clearUserCredentials(),
      ).thenAnswer((_) async {});

      // assert later
      final expected = [HomeInitial()];
      expectLater(homeBloc.stream, emitsInOrder(expected));

      // act
      homeBloc.add(const LogoutUser());

      // assert
      await untilCalled(() => mockStorageService.clearUserCredentials());
      verify(() => mockStorageService.clearUserCredentials()).called(1);
    });
  });
}
