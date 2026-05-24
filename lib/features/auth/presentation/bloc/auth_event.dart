// lib/features/auth/presentation/bloc/auth_event.dart
//
// AuthEvent — events for the global AuthBloc.

part of 'auth_bloc.dart';

/// Base class for all authentication events.
sealed class AuthEvent {
  const AuthEvent();
}

/// Dispatched on app startup to begin listening to the auth state stream.
final class AuthStarted extends AuthEvent {
  /// Creates an [AuthStarted] event.
  const AuthStarted();
}

/// Dispatched when the user requests to sign out.
final class AuthSignedOut extends AuthEvent {
  /// Creates an [AuthSignedOut] event.
  const AuthSignedOut();
}

/// Internal event dispatched when the Firebase auth state changes.
final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final AppUser? user;
}
