import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/exceptions/auth_exception.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/presentation/bloc/login_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LoginBloc', () {
    late MockAuthRepository mockAuthRepository;
    late LoginBloc loginBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      loginBloc = LoginBloc(repository: mockAuthRepository);
    });

    tearDown(() {
      loginBloc.close();
    });

    group('Email+password sign-in', () {
      test('calls signInWithEmail on repository when event added', () async {
        when(() => mockAuthRepository.signInWithEmail(
              any(),
              any(),
            )).thenAnswer((_) async {});

        loginBloc.add(const LoginEmailSignInRequested(
          email: 'test@example.com',
          password: 'password123',
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockAuthRepository.signInWithEmail(
          'test@example.com',
          'password123',
        )).called(1);
      });

      test('emits error state when sign-in fails', () async {
        when(() => mockAuthRepository.signInWithEmail(
              any(),
              any(),
            )).thenThrow(const AuthException(code: 'wrong-password'));

        loginBloc.add(const LoginEmailSignInRequested(
          email: 'test@example.com',
          password: 'wrongpassword',
        ));

        // Wait for event processing
        await Future.delayed(const Duration(milliseconds: 100));

        expect(loginBloc.state, isA<LoginFailure>());
      });
    });

    group('Google sign-in', () {
      test('calls signInWithGoogle on repository when event added', () async {
        when(() => mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async {});

        loginBloc.add(const LoginGoogleSignInRequested());

        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockAuthRepository.signInWithGoogle()).called(1);
      });

      test('emits error state when Google sign-in fails', () async {
        when(() => mockAuthRepository.signInWithGoogle())
            .thenThrow(const AuthException(code: 'popup-closed-by-user'));

        loginBloc.add(const LoginGoogleSignInRequested());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(loginBloc.state, isA<LoginFailure>());
      });
    });
  });
}
