// lib/features/auth/presentation/bloc/sign_up_state.dart
//
// SignUpState — states for the SignUpBloc.

part of 'sign_up_bloc.dart';

/// Base class for sign-up form states.
sealed class SignUpState {
  const SignUpState();
}

/// Initial state — no submission has been attempted.
final class SignUpInitial extends SignUpState {
  /// Creates a [SignUpInitial] state.
  const SignUpInitial();
}

/// State while the account-creation request is in flight.
final class SignUpLoading extends SignUpState {
  /// Creates a [SignUpLoading] state.
  const SignUpLoading();
}

/// State emitted when account creation fails.
final class SignUpFailure extends SignUpState {
  /// Creates a [SignUpFailure] state.
  const SignUpFailure({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignUpFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
