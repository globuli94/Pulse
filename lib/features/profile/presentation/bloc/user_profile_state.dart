// lib/features/profile/presentation/bloc/user_profile_state.dart
//
// UserProfileState — states for the screen-scoped UserProfileBloc.

part of 'user_profile_bloc.dart';

/// Base class for all user-profile-view states.
sealed class UserProfileState extends Equatable {
  const UserProfileState();
}

/// Initial state before any load has been requested.
final class UserProfileInitial extends UserProfileState {
  /// Creates a [UserProfileInitial] state.
  const UserProfileInitial();

  @override
  List<Object?> get props => [];
}

/// State while the profile is being loaded.
final class UserProfileLoading extends UserProfileState {
  /// Creates a [UserProfileLoading] state.
  const UserProfileLoading();

  @override
  List<Object?> get props => [];
}

/// State when the profile has been successfully loaded.
final class UserProfileLoaded extends UserProfileState {
  /// Creates a [UserProfileLoaded] state.
  const UserProfileLoaded(this.profile);

  /// The loaded user profile.
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// State when the profile load has failed.
final class UserProfileError extends UserProfileState {
  /// Creates a [UserProfileError] state.
  const UserProfileError(this.message);

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
