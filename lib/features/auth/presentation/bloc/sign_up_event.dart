// lib/features/auth/presentation/bloc/sign_up_event.dart
//
// SignUpEvent — events for the SignUpBloc.

part of 'sign_up_bloc.dart';

/// Base class for sign-up form events.
sealed class SignUpEvent {
  const SignUpEvent();
}

/// Dispatched when the user submits the registration form.
final class SignUpRequested extends SignUpEvent {
  /// Creates a [SignUpRequested] event.
  const SignUpRequested({
    required this.email,
    required this.password,
  });

  /// The email entered by the user.
  final String email;

  /// The password entered by the user.
  final String password;
}
