// lib/features/auth/presentation/bloc/login_state.dart
//
// LoginState — states for the LoginBloc.

part of 'login_bloc.dart';

/// Base class for login form states.
sealed class LoginState {
  const LoginState();
}

/// Initial state — no submission has been attempted.
final class LoginInitial extends LoginState {
  /// Creates a [LoginInitial] state.
  const LoginInitial();
}

/// State while a sign-in request is in flight.
final class LoginLoading extends LoginState {
  /// Creates a [LoginLoading] state.
  const LoginLoading();
}

/// State emitted when sign-in fails.
final class LoginFailure extends LoginState {
  /// Creates a [LoginFailure] state.
  const LoginFailure({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
