// lib/features/profile/data/repositories/profile_repository_impl.dart
//
// ProfileRepositoryImpl — concrete implementation of ProfileRepository.

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

/// Firebase-backed implementation of [ProfileRepository].
class ProfileRepositoryImpl implements ProfileRepository {
  /// Creates a [ProfileRepositoryImpl].
  ProfileRepositoryImpl({required ProfileRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final ProfileRemoteDataSource _dataSource;

  @override
  Future<UserProfile> getProfile(String uid) async {
    final data = await _dataSource.getProfile(uid);
    return UserProfile(
      uid: data['uid'] as String? ?? uid,
      displayName: data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      postCount: (data['postCount'] as num?)?.toInt() ?? 0,
      followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    await _dataSource.updateProfile(
      uid: uid,
      displayName: displayName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required String localFilePath,
  }) async {
    return await _dataSource.uploadAvatar(
      uid: uid,
      localFilePath: localFilePath,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _dataSource.deleteAccount();
  }

  @override
  Stream<({String displayName, String? avatarUrl})> watchUserDisplayInfo(String uid) =>
      _dataSource.watchUserDisplayInfo(uid);
}
