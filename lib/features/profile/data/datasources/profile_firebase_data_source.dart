// lib/features/profile/data/datasources/profile_firebase_data_source.dart
//
// ProfileFirebaseDataSource — Firebase implementation of ProfileRemoteDataSource.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  Future<Map<String, dynamic>> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('User profile not found for uid: $uid');
    }
    return doc.data()!;
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) data['displayName'] = displayName;
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (data.isEmpty) return;

    await _firestore.collection('users').doc(uid).update(data);

    // Propagate displayName/avatarUrl to all posts by this user.
    final postUpdates = <String, dynamic>{};
    if (displayName != null) postUpdates['displayName'] = displayName;
    if (avatarUrl != null) postUpdates['avatarUrl'] = avatarUrl;

    if (postUpdates.isNotEmpty) {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.update(doc.reference, postUpdates);
        }
        await batch.commit();
      }
    }
  }

  @override
  Future<String> uploadAvatar({
    required String uid,
    required String localFilePath,
  }) async {
    final ref = _storage.ref().child('avatars/$uid');
    final file = File(localFilePath);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _firebaseAuth.currentUser!.uid;
    // 1. Delete Firestore document.
    await _firestore.collection('users').doc(uid).delete();
    // 2. Delete Storage avatar (swallow object-not-found).
    try {
      await _storage.ref().child('avatars/$uid').delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
    // 3. Delete Firebase Auth account.
    await _firebaseAuth.currentUser!.delete();
  }
}
