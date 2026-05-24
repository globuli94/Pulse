// lib/features/profile/data/datasources/profile_firebase_data_source.dart
//
// ProfileFirebaseDataSource — Firebase implementation of ProfileRemoteDataSource.

import 'dart:typed_data';

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
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _storage = storage,
        _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<UserProfile> getProfile(String uid) async {
    final snapshot =
        await _firestore.collection('users').doc(uid).get();

    if (!snapshot.exists) {
      throw const ProfileException(message: 'User not found.');
    }

    final data = snapshot.data()!;
    return UserProfile(
      uid: data['uid'] as String,
      displayName: data['displayName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      postCount: (data['postCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'displayName': displayName,
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required List<int> imageBytes,
    required String filename,
  }) async {
    final ref = _storage.ref('avatars/$uid/$filename');
    await ref.putData(Uint8List.fromList(imageBytes));
    final downloadUrl = await ref.getDownloadURL();
    await _firestore.collection('users').doc(uid).update({
      'avatarUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return downloadUrl;
  }

  @override
  Future<void> deleteAccount(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    await _firebaseAuth.currentUser!.delete();
  }
}
