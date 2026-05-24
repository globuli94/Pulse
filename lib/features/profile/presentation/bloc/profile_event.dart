// lib/features/profile/presentation/bloc/profile_event.dart
//
// ProfileEvent — events for ProfileBloc.

part of 'profile_bloc.dart';

/// Base class for all profile events.
sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
}

/// Request to load the profile for [uid].
final class ProfileLoadRequested extends ProfileEvent {
  /// Creates a [ProfileLoadRequested] event.
  const ProfileLoadRequested({required this.uid});

  /// The uid of the profile to load.
  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Request to update the profile for [uid] with new [displayName] and [bio].
final class ProfileUpdateRequested extends ProfileEvent {
  /// Creates a [ProfileUpdateRequested] event.
  const ProfileUpdateRequested({
    required this.uid,
    required this.displayName,
    required this.bio,
  });

  /// The uid of the user whose profile is being updated.
  final String uid;

  /// The new display name.
  final String displayName;

  /// The new bio.
  final String bio;

  @override
  List<Object?> get props => [uid, displayName, bio];
}

/// Request to upload an avatar for [uid].
final class AvatarUploadRequested extends ProfileEvent {
  /// Creates an [AvatarUploadRequested] event.
  const AvatarUploadRequested({
    required this.uid,
    required this.imageBytes,
    required this.filename,
  });

  /// The uid of the user whose avatar is being uploaded.
  final String uid;

  /// The raw bytes of the image to upload.
  final List<int> imageBytes;

  /// The filename for the uploaded image.
  final String filename;

  @override
  List<Object?> get props => [uid, imageBytes, filename];
}

/// Request to delete the account for [uid].
final class AccountDeleteRequested extends ProfileEvent {
  /// Creates an [AccountDeleteRequested] event.
  const AccountDeleteRequested({required this.uid});

  /// The uid of the user whose account is being deleted.
  final String uid;

  @override
  List<Object?> get props => [uid];
}
