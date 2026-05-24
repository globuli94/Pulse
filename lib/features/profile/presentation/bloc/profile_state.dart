// lib/features/profile/presentation/bloc/profile_state.dart
//
// ProfileState — states for ProfileBloc.

part of 'profile_bloc.dart';

/// Base class for all profile states.
sealed class ProfileState extends Equatable {
  const ProfileState();
}

/// Initial state before any profile has been loaded.
final class ProfileInitial extends ProfileState {
  /// Creates a [ProfileInitial] state.
  const ProfileInitial();

  @override
  List<Object?> get props => [];
}

/// Profile is loading.
final class ProfileLoading extends ProfileState {
  /// Creates a [ProfileLoading] state.
  const ProfileLoading();

  @override
  List<Object?> get props => [];
}

/// Profile has been loaded successfully.
final class ProfileLoaded extends ProfileState {
  /// Creates a [ProfileLoaded] state.
  const ProfileLoaded({required this.profile});

  /// The loaded user profile.
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// Profile is being updated. Carries the stale profile for display.
final class ProfileUpdating extends ProfileState {
  /// Creates a [ProfileUpdating] state.
  const ProfileUpdating({required this.profile});

  /// The stale profile shown while the update is running.
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// A profile operation failed.
final class ProfileFailure extends ProfileState {
  /// Creates a [ProfileFailure] state.
  const ProfileFailure({required this.error});

  /// A human-readable error message.
  final String error;

  @override
  List<Object?> get props => [error];
}

/// Account has been deleted successfully.
final class AccountDeleteSuccess extends ProfileState {
  /// Creates an [AccountDeleteSuccess] state.
  const AccountDeleteSuccess();

  @override
  List<Object?> get props => [];
}
