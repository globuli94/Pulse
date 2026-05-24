import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/exceptions/auth_exception.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/presentation/bloc/sign_up_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SignUpBloc', () {
    late MockAuthRepository mockAuthRepository;
    late SignUpBloc signUpBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      signUpBloc = SignUpBloc(repository: mockAuthRepository);
    });

    tearDown(() {
      signUpBloc.close();
    });

    test('calls signUpWithEmail on repository when event added', () async {
      when(() => mockAuthRepository.signUpWithEmail(
            any(),
            any(),
          )).thenAnswer((_) async {});

      signUpBloc.add(const SignUpRequested(
        email: 'newuser@example.com',
        password: 'password123',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockAuthRepository.signUpWithEmail(
        'newuser@example.com',
        'password123',
      )).called(1);
    });

    test('emits error state when sign-up fails', () async {
      when(() => mockAuthRepository.signUpWithEmail(
            any(),
            any(),
          )).thenThrow(const AuthException(code: 'email-already-in-use'));

      signUpBloc.add(const SignUpRequested(
        email: 'existing@example.com',
        password: 'password123',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(signUpBloc.state, isA<SignUpFailure>());
    });

    test('delegates to repository for sign-up submission', () async {
      when(() => mockAuthRepository.signUpWithEmail(
            any(),
            any(),
          )).thenAnswer((_) async {});

      signUpBloc.add(const SignUpRequested(
        email: 'test@example.com',
        password: 'password123',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockAuthRepository.signUpWithEmail(
        'test@example.com',
        'password123',
      )).called(1);
    });
  });
}
