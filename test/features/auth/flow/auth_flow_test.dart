import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('Authentication Flow - AuthBloc', () {
    late MockAuthRepository mockRepository;
    late AuthBloc authBloc;

    setUp(() {
      mockRepository = MockAuthRepository();
      authBloc = AuthBloc(repository: mockRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test(
      'Unauthenticated state → AuthBloc emits Unauthenticated when stream emits null',
      () async {
        when(() => mockRepository.authStateChanges).thenAnswer(
          (_) => Stream.value(null),
        );

        authBloc.add(const AuthStarted());

        await expectLater(
          authBloc.stream,
          emits(isA<Unauthenticated>()),
        );
      },
    );

    test(
      'After authentication → AuthBloc emits Authenticated when stream emits user',
      () async {
        final testUser = AppUser(
          uid: 'test-uid',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        when(() => mockRepository.authStateChanges).thenAnswer(
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
      },
    );

    test(
      'From Authenticated state, logout calls signOut',
      () async {
        when(() => mockRepository.signOut()).thenAnswer((_) async {});

        authBloc.add(const AuthSignedOut());

        await Future.delayed(const Duration(milliseconds: 50));

        verify(() => mockRepository.signOut()).called(1);
      },
    );
  });
}
