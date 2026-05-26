// lib/features/follows/data/repositories/follows_repository_impl.dart
//
// FollowsRepositoryImpl — concrete implementation of FollowsRepository.

import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/repositories/follows_repository.dart';
import '../datasources/follows_remote_data_source.dart';

/// Firebase-backed implementation of [FollowsRepository].
///
/// Thin delegation layer — all calls are forwarded to [FollowsRemoteDataSource].
class FollowsRepositoryImpl implements FollowsRepository {
  /// Creates a [FollowsRepositoryImpl].
  FollowsRepositoryImpl({required FollowsRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final FollowsRemoteDataSource _dataSource;

  @override
  Future<void> followUser({
    required String followerId,
    required String followeeId,
  }) =>
      _dataSource.followUser(followerId: followerId, followeeId: followeeId);

  @override
  Future<void> unfollowUser({
    required String followerId,
    required String followeeId,
  }) =>
      _dataSource.unfollowUser(followerId: followerId, followeeId: followeeId);

  @override
  Future<bool> isFollowing({
    required String followerId,
    required String followeeId,
  }) =>
      _dataSource.isFollowing(followerId: followerId, followeeId: followeeId);

  @override
  Future<List<String>> getFollowedUserIds({required String followerId}) =>
      _dataSource.getFollowedUserIds(followerId: followerId);

  @override
  Future<List<UserProfile>> getFollowers(String uid) async {
    final maps = await _dataSource.getFollowers(uid);
    return maps.map(_mapToUserProfile).toList();
  }

  @override
  Future<List<UserProfile>> getFollowing(String uid) async {
    final maps = await _dataSource.getFollowing(uid);
    return maps.map(_mapToUserProfile).toList();
  }

  UserProfile _mapToUserProfile(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      postCount: (data['postCount'] as num?)?.toInt() ?? 0,
      followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
