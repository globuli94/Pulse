// lib/features/auth/presentation/bloc/login_bloc.dart
//
// LoginBloc — handles email/password and Google sign-in form submissions.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

/// BLoC that manages the login form's loading and error state.
///
/// On success, [AuthBloc] automatically transitions to [Authenticated] via
/// the shared [AuthRepository.authStateChanges] stream.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  /// Creates a [LoginBloc].
  LoginBloc({required AuthRepository repository})
      : _repository = repository,
        super(const LoginInitial()) {
    on<LoginEmailSignInRequested>(_onEmailSignInRequested);
    on<LoginGoogleSignInRequested>(_onGoogleSignInRequested);
  }

  final AuthRepository _repository;

  Future<void> _onEmailSignInRequested(
    LoginEmailSignInRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());
    try {
      await _repository.signInWithEmail(event.email, event.password);
      emit(const LoginInitial());
    } on AuthException catch (e) {
      emit(LoginFailure(message: e.message ?? 'Sign-in failed. Please try again.'));
    } catch (_) {
      emit(const LoginFailure(message: 'An unexpected error occurred.'));
    }
  }

  Future<void> _onGoogleSignInRequested(
    LoginGoogleSignInRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());
    try {
      await _repository.signInWithGoogle();
      emit(const LoginInitial());
    } on AuthException catch (e) {
      emit(LoginFailure(message: e.message ?? 'Sign-in failed. Please try again.'));
    } catch (_) {
      emit(const LoginFailure(message: 'An unexpected error occurred.'));
    }
  }
}
