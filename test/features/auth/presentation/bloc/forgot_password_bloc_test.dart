import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/exceptions/auth_exception.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/presentation/bloc/forgot_password_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('ForgotPasswordBloc', () {
    late MockAuthRepository mockAuthRepository;
    late ForgotPasswordBloc forgotPasswordBloc;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      forgotPasswordBloc = ForgotPasswordBloc(repository: mockAuthRepository);
    });

    tearDown(() {
      forgotPasswordBloc.close();
    });

    test('calls sendPasswordResetEmail on repository when event added', () async {
      when(() => mockAuthRepository.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      forgotPasswordBloc.add(const ForgotPasswordResetRequested(
        email: 'test@example.com',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      verify(() => mockAuthRepository.sendPasswordResetEmail(
        'test@example.com',
      )).called(1);
    });

    test('emits error state when sendPasswordResetEmail fails', () async {
      when(() => mockAuthRepository.sendPasswordResetEmail(any()))
          .thenThrow(const AuthException(code: 'user-not-found'));

      forgotPasswordBloc.add(const ForgotPasswordResetRequested(
        email: 'nonexistent@example.com',
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(forgotPasswordBloc.state, isA<ForgotPasswordFailure>());
    });
  });
}
