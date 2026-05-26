// lib/features/follows/data/datasources/follows_remote_data_source.dart
//
// FollowsRemoteDataSource — abstract interface for follows data operations.

/// Abstract interface that all follows remote data sources must implement.
///
/// Mirrors [FollowsRepository] exactly. The data source does not know about
/// domain entities.
abstract class FollowsRemoteDataSource {
  /// Creates a follow relationship from [followerId] to [followeeId].
  ///
  /// Both operations run as a Firestore [WriteBatch] for atomicity.
  Future<void> followUser({
    required String followerId,
    required String followeeId,
  });

  /// Removes the follow relationship from [followerId] to [followeeId].
  ///
  /// Both operations run as a Firestore [WriteBatch] for atomicity.
  Future<void> unfollowUser({
    required String followerId,
    required String followeeId,
  });

  /// Returns true if [followerId] currently follows [followeeId].
  Future<bool> isFollowing({
    required String followerId,
    required String followeeId,
  });

  /// Returns the list of UIDs that [followerId] currently follows.
  Future<List<String>> getFollowedUserIds({required String followerId});

  /// Returns raw user maps for all followers of [uid].
  Future<List<Map<String, dynamic>>> getFollowers(String uid);

  /// Returns raw user maps for all users that [uid] follows.
  Future<List<Map<String, dynamic>>> getFollowing(String uid);
}
