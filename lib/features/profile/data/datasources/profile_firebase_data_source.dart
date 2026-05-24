// lib/features/profile/data/datasources/profile_firebase_data_source.dart
//
// ProfileFirebaseDataSource — Firebase implementation of ProfileRemoteDataSource.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/exceptions/profile_exception.dart';
import 'profile_remote_data_source.dart';

/// Firebase-backed implementation of [ProfileRemoteDataSource].
class ProfileFirebaseDataSource implements ProfileRemoteDataSource {
  /// Creates a [ProfileFirebaseDataSource].
  ProfileFirebaseDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore,
        _storage = storage,
        _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth? _firebaseAuth;

  @override
  Future<UserProfile> getProfile(String uid) async {
    final snapshot =
        await _firestore.collection('users').doc(uid).get();

    if (!snapshot.exists) {
      throw const ProfileException('User not found.');
    }

    final data = snapshot.data()!;
    return UserProfile(
      uid: data['uid'] as String,
      displayName: data['displayName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      postCount: (data['postCount'] as num?)?.toInt() ?? 0,
      followerCount: (data['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (data['followingCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  Future<UserProfile> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    if (displayName.isEmpty) {
      throw const ProfileException('Display name must not be empty.');
    }
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return getProfile(uid);
  }

  @override
  Future<UserProfile> uploadAvatar({
    required String uid,
    required String imagePath,
  }) async {
    try {
      final filename = imagePath.split('/').last;
      final ref = _storage.ref('avatars/$uid/$filename');
      await ref.putFile(File(imagePath));
      final downloadUrl = await ref.getDownloadURL();
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return getProfile(uid);
    } catch (e) {
      if (e is ProfileException) rethrow;
      throw ProfileException('Failed to upload avatar.');
    }
  }

  @override
  Future<void> deleteAccount({required String uid}) async {
    await _firestore.collection('users').doc(uid).delete();
    await _firebaseAuth?.currentUser?.delete();
  }
}
