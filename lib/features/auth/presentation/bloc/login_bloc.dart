// lib/features/auth/presentation/bloc/login_bloc.dart
//
// LoginBloc — handles email/password and Google sign-in form submissions.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    } on FirebaseAuthException catch (e) {
      emit(LoginFailure(message: _messageFromCode(e.code)));
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
    } on FirebaseAuthException catch (e) {
      emit(LoginFailure(message: _messageFromCode(e.code)));
    } catch (_) {
      emit(const LoginFailure(message: 'An unexpected error occurred.'));
    }
  }

  String _messageFromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }
}
