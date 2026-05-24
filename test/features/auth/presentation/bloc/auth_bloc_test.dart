import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthBloc', () {
    late MockAuthRepository mockAuthRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(repository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    group('AuthStarted event', () {
      test('emits Authenticated when authStateChanges emits a non-null user',
          () async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        when(() => mockAuthRepository.authStateChanges).thenAnswer(
          (_) => Stream.value(testUser),
        );

        authBloc.add(const AuthStarted());

        await expectLater(
          authBloc.stream,
          emits(
            isA<Authenticated>().having(
              (state) => state.user.uid,
              'uid',
              'test-uid',
            ),
          ),
        );
      });

      test('emits Unauthenticated when authStateChanges emits null', () async {
        when(() => mockAuthRepository.authStateChanges).thenAnswer(
          (_) => Stream.value(null),
        );

        authBloc.add(const AuthStarted());

        await expectLater(
          authBloc.stream,
          emits(isA<Unauthenticated>()),
        );
      });

    });

    group('AuthSignedOut event', () {
      test('calls signOut on the repository', () async {
        when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

        authBloc.add(const AuthSignedOut());

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockAuthRepository.signOut()).called(1);
      });

    });
  });
}
