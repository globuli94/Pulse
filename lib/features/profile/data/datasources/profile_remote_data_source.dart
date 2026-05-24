// lib/features/profile/data/datasources/profile_remote_data_source.dart
//
// ProfileRemoteDataSource — abstract interface for remote profile data.

import '../../domain/entities/user_profile.dart';

/// Abstract data source for remote user profile operations.
abstract class ProfileRemoteDataSource {
  /// Fetches the profile for [uid].
  Future<UserProfile> getProfile(String uid);

  /// Updates the [displayName] and [bio] fields for [uid].
  ///
  /// Returns the updated [UserProfile].
  Future<UserProfile> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  });

  /// Uploads the image at [imagePath] as the avatar for [uid].
  ///
  /// Returns the updated [UserProfile] with the new avatar URL.
  Future<UserProfile> uploadAvatar({
    required String uid,
    required String imagePath,
  });

  /// Deletes the Firestore document and the Firebase Auth account for [uid].
  Future<void> deleteAccount({required String uid});
}
