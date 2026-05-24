// lib/features/auth/presentation/bloc/sign_up_bloc.dart
//
// SignUpBloc — handles email/password account-creation form submissions.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

/// BLoC that manages the sign-up form's loading and error state.
///
/// On success, [AuthBloc] automatically transitions to [Authenticated] via
/// the shared [AuthRepository.authStateChanges] stream.
class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  /// Creates a [SignUpBloc].
  SignUpBloc({required AuthRepository repository})
      : _repository = repository,
        super(const SignUpInitial()) {
    on<SignUpRequested>(_onSignUpRequested);
  }

  final AuthRepository _repository;

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<SignUpState> emit,
  ) async {
    emit(const SignUpLoading());
    try {
      await _repository.signUpWithEmail(event.email, event.password);
      emit(const SignUpInitial());
    } on AuthException catch (e) {
      emit(SignUpFailure(message: e.message ?? 'Account creation failed. Please try again.'));
    } catch (_) {
      emit(const SignUpFailure(message: 'An unexpected error occurred.'));
    }
  }
}
