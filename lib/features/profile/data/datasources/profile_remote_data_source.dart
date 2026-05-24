// lib/features/profile/data/datasources/profile_remote_data_source.dart
//
// ProfileRemoteDataSource — abstract interface for profile data operations.

/// Abstract interface for remote profile data operations.
///
/// Implementations return raw maps, never domain entities.
abstract class ProfileRemoteDataSource {
  /// Fetches the raw Firestore document data for `users/{uid}`.
  Future<Map<String, dynamic>> getProfile(String uid);

  /// Updates editable fields on `users/{uid}`.
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
  });

  /// Uploads an avatar file to `avatars/{uid}` in Firebase Storage.
  ///
  /// Returns the public HTTPS download URL.
  Future<String> uploadAvatar({
    required String uid,
    required String localFilePath,
  });

  /// Deletes the current user's account:
  ///
  /// 1. Deletes `users/{uid}` Firestore document.
  /// 2. Deletes `avatars/{uid}` from Firebase Storage (swallows NotFound).
  /// 3. Deletes the Firebase Auth account.
  Future<void> deleteAccount();
}
