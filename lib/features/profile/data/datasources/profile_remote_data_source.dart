// lib/features/profile/data/datasources/profile_remote_data_source.dart
//
// ProfileRemoteDataSource — abstract interface for remote profile data.

import '../../domain/entities/user_profile.dart';

/// Abstract data source for remote user profile operations.
abstract class ProfileRemoteDataSource {
  /// Fetches the profile for [uid].
  Future<UserProfile> getProfile(String uid);

  /// Updates the [displayName] and [bio] fields for [uid].
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  });

  /// Uploads [imageBytes] as the avatar for [uid].
  ///
  /// Returns the public download URL of the uploaded avatar.
  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String filename,
  });

  /// Deletes the Firestore document and the Firebase Auth account for [uid].
  Future<void> deleteAccount(String uid);
}
