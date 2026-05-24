// lib/features/profile/data/repositories/profile_repository_impl.dart
//
// ProfileRepositoryImpl — delegates to ProfileRemoteDataSource, wrapping
// all exceptions as ProfileException.

import '../../domain/entities/user_profile.dart';
import '../../domain/exceptions/profile_exception.dart';
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
    try {
      return await _dataSource.getProfile(uid);
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  @override
  Future<UserProfile> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    try {
      return await _dataSource.updateProfile(
        uid: uid,
        displayName: displayName,
        bio: bio,
      );
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  @override
  Future<UserProfile> uploadAvatar({
    required String uid,
    required String imagePath,
  }) async {
    try {
      return await _dataSource.uploadAvatar(
        uid: uid,
        imagePath: imagePath,
      );
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }

  @override
  Future<void> deleteAccount({required String uid}) async {
    try {
      await _dataSource.deleteAccount(uid: uid);
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException(e.toString());
    }
  }
}
