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
      throw ProfileException(message: e.toString());
    }
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    try {
      await _dataSource.updateProfile(
        uid: uid,
        displayName: displayName,
        bio: bio,
      );
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException(message: e.toString());
    }
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String filename,
  }) async {
    try {
      return await _dataSource.uploadAvatar(
        uid: uid,
        imageBytes: imageBytes,
        filename: filename,
      );
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException(message: e.toString());
    }
  }

  @override
  Future<void> deleteAccount(String uid) async {
    try {
      await _dataSource.deleteAccount(uid);
    } on ProfileException {
      rethrow;
    } catch (e) {
      throw ProfileException(message: e.toString());
    }
  }
}
