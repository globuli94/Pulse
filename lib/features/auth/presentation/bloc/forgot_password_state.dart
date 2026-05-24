// lib/features/auth/presentation/bloc/forgot_password_state.dart
//
// ForgotPasswordState — states for the ForgotPasswordBloc.

part of 'forgot_password_bloc.dart';

/// Base class for forgot-password form states.
sealed class ForgotPasswordState {
  const ForgotPasswordState();
}

/// Initial state — no submission has been attempted.
final class ForgotPasswordInitial extends ForgotPasswordState {
  /// Creates a [ForgotPasswordInitial] state.
  const ForgotPasswordInitial();
}

/// State while the password-reset email request is in flight.
final class ForgotPasswordLoading extends ForgotPasswordState {
  /// Creates a [ForgotPasswordLoading] state.
  const ForgotPasswordLoading();
}

/// State emitted when the reset email is sent successfully.
final class ForgotPasswordSuccess extends ForgotPasswordState {
  /// Creates a [ForgotPasswordSuccess] state.
  const ForgotPasswordSuccess();
}

/// State emitted when the reset request fails.
final class ForgotPasswordFailure extends ForgotPasswordState {
  /// Creates a [ForgotPasswordFailure] state.
  const ForgotPasswordFailure({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgotPasswordFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
