// lib/features/auth/presentation/bloc/forgot_password_event.dart
//
// ForgotPasswordEvent — events for the ForgotPasswordBloc.

part of 'forgot_password_bloc.dart';

/// Base class for forgot-password form events.
sealed class ForgotPasswordEvent {
  const ForgotPasswordEvent();
}

/// Dispatched when the user submits their email for a password reset.
final class ForgotPasswordResetRequested extends ForgotPasswordEvent {
  /// Creates a [ForgotPasswordResetRequested] event.
  const ForgotPasswordResetRequested({required this.email});

  /// The email address to send the reset link to.
  final String email;
}
