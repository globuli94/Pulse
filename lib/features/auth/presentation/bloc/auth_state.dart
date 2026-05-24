// lib/features/auth/presentation/bloc/auth_state.dart
//
// AuthState — states for the global AuthBloc.

part of 'auth_bloc.dart';

/// Base class for all authentication states.
sealed class AuthState {
  const AuthState();
}

/// Initial state before the auth stream has emitted any value.
final class AuthInitial extends AuthState {
  /// Creates an [AuthInitial] state.
  const AuthInitial();
}

/// State representing a successfully authenticated user.
final class Authenticated extends AuthState {
  /// Creates an [Authenticated] state.
  const Authenticated(this.user);

  /// The currently authenticated user.
  final AppUser user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Authenticated && other.user == user;

  @override
  int get hashCode => user.hashCode;
}

/// State representing no authenticated user.
final class Unauthenticated extends AuthState {
  /// Creates an [Unauthenticated] state.
  const Unauthenticated();
}
