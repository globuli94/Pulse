// lib/features/profile/presentation/bloc/profile_event.dart
//
// ProfileEvent — events for the global ProfileBloc.

part of 'profile_bloc.dart';

/// Base class for all profile events.
sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
}

/// Dispatched to load the profile for the given [uid].
final class ProfileLoadRequested extends ProfileEvent {
  /// Creates a [ProfileLoadRequested] event.
  const ProfileLoadRequested({required this.uid});

  /// The UID of the user whose profile to load.
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Dispatched to update editable profile fields for the current user.
final class ProfileUpdateRequested extends ProfileEvent {
  /// Creates a [ProfileUpdateRequested] event.
  const ProfileUpdateRequested({
    required this.uid,
    this.displayName,
    this.bio,
    this.avatarFilePath,
  });

  /// The UID of the user whose profile to update.
  final String uid;

  /// New display name, or null to leave unchanged.
  final String? displayName;

  /// New bio, or null to leave unchanged.
  final String? bio;

  /// Local file path of the new avatar image, or null for no change.
  final String? avatarFilePath;

  @override
  List<Object?> get props => [uid, displayName, bio, avatarFilePath];
}

/// Dispatched when the user requests to sign out.
final class ProfileSignOutRequested extends ProfileEvent {
  /// Creates a [ProfileSignOutRequested] event.
  const ProfileSignOutRequested();

  @override
  List<Object?> get props => [];
}

/// Dispatched when the user requests to delete their account.
final class ProfileDeleteAccountRequested extends ProfileEvent {
  /// Creates a [ProfileDeleteAccountRequested] event.
  const ProfileDeleteAccountRequested();

  @override
  List<Object?> get props => [];
}
