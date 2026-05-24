// lib/features/auth/presentation/bloc/login_event.dart
//
// LoginEvent — events for the LoginBloc.

part of 'login_bloc.dart';

/// Base class for login form events.
sealed class LoginEvent {
  const LoginEvent();
}

/// Dispatched when the user submits the email/password login form.
final class LoginEmailSignInRequested extends LoginEvent {
  /// Creates a [LoginEmailSignInRequested] event.
  const LoginEmailSignInRequested({
    required this.email,
    required this.password,
  });

  /// The email entered by the user.
  final String email;

  /// The password entered by the user.
  final String password;
}

/// Dispatched when the user taps "Sign in with Google".
final class LoginGoogleSignInRequested extends LoginEvent {
  /// Creates a [LoginGoogleSignInRequested] event.
  const LoginGoogleSignInRequested();
}
