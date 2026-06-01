// lib/features/profile/data/datasources/profile_firebase_data_source.dart
//
// ProfileFirebaseDataSource — Firebase implementation of ProfileRemoteDataSource.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

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
    final docFuture = _firestore.collection('users').doc(uid).get();
    final postCountFuture = _firestore
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .count()
        .get();
    final followerCountFuture = _firestore
        .collection('follows')
        .where('followeeId', isEqualTo: uid)
        .count()
        .get();
    final followingCountFuture = _firestore
        .collection('follows')
        .where('followerId', isEqualTo: uid)
        .count()
        .get();

    final doc = await docFuture;
    if (!doc.exists || doc.data() == null) {
      throw Exception('User profile not found for uid: $uid');
    }
    final postCountSnap = await postCountFuture;
    final followerCountSnap = await followerCountFuture;
    final followingCountSnap = await followingCountFuture;

    return <String, dynamic>{
      'uid': doc.id,
      ...?doc.data(),
      'postCount': postCountSnap.count ?? 0,
      'followerCount': followerCountSnap.count ?? 0,
      'followingCount': followingCountSnap.count ?? 0,
    };
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
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user');
    final uid = user.uid;

    // Deletion order: user-owned content first → user document → Auth record.
    // All Firestore writes must complete before the auth token is invalidated.

    // 1. Delete all posts authored by the user.
    await _deleteByField('posts', 'userId', uid);

    // 2. Delete all likes created by the user.
    await _deleteByField('likes', 'userId', uid);

    // 3. Delete follow relationships where the user is the follower.
    await _deleteByField('follows', 'followerId', uid);

    // 4. Delete follow relationships where the user is the followee.
    //    Best-effort: requires Firestore rule
    //    `allow delete if resource.data.followeeId == request.auth.uid`.
    try {
      await _deleteByField('follows', 'followeeId', uid);
    } on FirebaseException catch (e) {
      debugPrint('deleteAccount: follows(followeeId) cleanup skipped: $e');
    }

    // 5. Delete notifications received by the user.
    //    Best-effort: requires Firestore rule
    //    `allow delete if resource.data.userId == request.auth.uid`.
    try {
      await _deleteByField('notifications', 'userId', uid);
    } on FirebaseException catch (e) {
      debugPrint('deleteAccount: notifications(userId) cleanup skipped: $e');
    }

    // 6. Delete notifications caused by the user (appearing in other users'
    //    notification feeds).
    //    Best-effort: requires Firestore rule
    //    `allow delete if resource.data.actorId == request.auth.uid`.
    try {
      await _deleteByField('notifications', 'actorId', uid);
    } on FirebaseException catch (e) {
      debugPrint('deleteAccount: notifications(actorId) cleanup skipped: $e');
    }

    // 7. Delete conversations the user participates in, including their
    //    messages subcollections.
    //    Best-effort: requires Firestore `allow delete` on conversations and
    //    messages subcollection.
    try {
      await _deleteConversationsAndMessages(uid);
    } on FirebaseException catch (e) {
      debugPrint('deleteAccount: conversations/messages cleanup skipped: $e');
    }

    // 8. Delete the user document (must precede Auth deletion so rules pass).
    await _firestore.collection('users').doc(uid).delete();

    // 9. Delete Storage avatar (swallow object-not-found).
    try {
      await _storage.ref().child('avatars/$uid').delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }

    // 10. Delete the Firebase Auth account — must be last.
    await user.delete();
  }

  @override
  Stream<({String displayName, String? avatarUrl})> watchUserDisplayInfo(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
      final data = snap.data() ?? {};
      return (
        displayName: (data['displayName'] as String?) ?? '',
        avatarUrl: data['avatarUrl'] as String?,
      );
    });
  }

  /// Deletes all documents in [collection] where [field] equals [value].
  ///
  /// Paginates in batches of 500 to respect the Firestore batch-write limit.
  Future<void> _deleteByField(
      String collection, String field, String value) async {
    while (true) {
      final snapshot = await _firestore
          .collection(collection)
          .where(field, isEqualTo: value)
          .limit(500)
          .get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 500) return;
    }
  }

  /// Deletes all conversations where [uid] is a participant, including each
  /// conversation's messages subcollection.
  ///
  /// Processes conversations in batches of 100 to bound total operations per
  /// iteration. Messages within each conversation are deleted first (Firestore
  /// does not cascade-delete subcollections).
  Future<void> _deleteConversationsAndMessages(String uid) async {
    while (true) {
      final snapshot = await _firestore
          .collection('conversations')
          .where('participantIds', arrayContains: uid)
          .limit(100)
          .get();
      if (snapshot.docs.isEmpty) return;
      for (final conversationDoc in snapshot.docs) {
        await _deleteMessages(conversationDoc.id);
      }
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 100) return;
    }
  }

  /// Deletes all messages within the conversation identified by [conversationId].
  ///
  /// Paginates in batches of 500 to respect the Firestore batch-write limit.
  Future<void> _deleteMessages(String conversationId) async {
    while (true) {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .limit(500)
          .get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 500) return;
    }
  }
}
