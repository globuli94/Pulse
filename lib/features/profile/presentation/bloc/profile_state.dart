// lib/features/profile/presentation/bloc/profile_state.dart
//
// ProfileState — states for the global ProfileBloc.

part of 'profile_bloc.dart';

/// Base class for all profile states.
sealed class ProfileState extends Equatable {
  const ProfileState();
}

/// Initial state before any profile load has been requested.
final class ProfileInitial extends ProfileState {
  /// Creates a [ProfileInitial] state.
  const ProfileInitial();

  @override
  List<Object?> get props => [];
}

/// State while a profile load or initial action is in progress.
final class ProfileLoading extends ProfileState {
  /// Creates a [ProfileLoading] state.
  const ProfileLoading();

  @override
  List<Object?> get props => [];
}

/// State when the profile has been successfully loaded.
final class ProfileLoaded extends ProfileState {
  /// Creates a [ProfileLoaded] state.
  const ProfileLoaded({required this.profile});

  /// The loaded user profile.
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// State when a profile operation has failed.
final class ProfileError extends ProfileState {
  /// Creates a [ProfileError] state.
  const ProfileError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// State while a profile update is in progress; carries stale data for display.
final class ProfileUpdating extends ProfileState {
  /// Creates a [ProfileUpdating] state.
  const ProfileUpdating({required this.profile});

  /// The profile data to show while the update is in progress.
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// State after a profile update has succeeded.
final class ProfileUpdateSuccess extends ProfileState {
  /// Creates a [ProfileUpdateSuccess] state.
  const ProfileUpdateSuccess({required this.profile});

  /// The updated user profile.
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// State after the user has successfully signed out.
final class ProfileSignedOut extends ProfileState {
  /// Creates a [ProfileSignedOut] state.
  const ProfileSignedOut();

  @override
  List<Object?> get props => [];
}

/// State after the user's account has been successfully deleted.
final class ProfileAccountDeleted extends ProfileState {
  /// Creates a [ProfileAccountDeleted] state.
  const ProfileAccountDeleted();

  @override
  List<Object?> get props => [];
}
