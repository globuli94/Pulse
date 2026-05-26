// lib/features/follows/domain/repositories/follows_repository.dart
//
// FollowsRepository — abstract interface for follow/unfollow operations.

import '../../../profile/domain/entities/user_profile.dart';

/// Abstract repository interface for all follow relationship operations.
///
/// Zero Firebase imports — implementations live in the data layer.
abstract class FollowsRepository {
  /// Creates a follow relationship from [followerId] to [followeeId].
  ///
  /// Atomically:
  /// 1. Writes `follows/{followerId}_{followeeId}`.
  /// 2. Increments `users/{followerId}.followingCount` by 1.
  /// 3. Increments `users/{followeeId}.followerCount` by 1.
  Future<void> followUser({
    required String followerId,
    required String followeeId,
  });

  /// Removes the follow relationship from [followerId] to [followeeId].
  ///
  /// Atomically:
  /// 1. Deletes `follows/{followerId}_{followeeId}`.
  /// 2. Decrements `users/{followerId}.followingCount` by 1 (min 0).
  /// 3. Decrements `users/{followeeId}.followerCount` by 1 (min 0).
  Future<void> unfollowUser({
    required String followerId,
    required String followeeId,
  });

  /// Returns true if [followerId] currently follows [followeeId].
  ///
  /// Implemented as an O(1) document existence check on
  /// `follows/{followerId}_{followeeId}`.
  Future<bool> isFollowing({
    required String followerId,
    required String followeeId,
  });

  /// Returns the list of UIDs that [followerId] currently follows.
  ///
  /// Queries `follows` where `followerId == followerId`, ordered by
  /// `createdAt ASC`. Returns an empty list if the user follows nobody.
  Future<List<String>> getFollowedUserIds({required String followerId});

  /// Returns the list of [UserProfile]s that follow [uid].
  ///
  /// Queries `follows` where `followeeId == uid`, then fetches each
  /// follower's `users/{followerId}` document.
  Future<List<UserProfile>> getFollowers(String uid);

  /// Returns the list of [UserProfile]s that [uid] follows.
  ///
  /// Queries `follows` where `followerId == uid`, then fetches each
  /// followee's `users/{followeeId}` document.
  Future<List<UserProfile>> getFollowing(String uid);
}
