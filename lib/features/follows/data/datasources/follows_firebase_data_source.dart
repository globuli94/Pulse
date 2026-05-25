// lib/features/follows/data/datasources/follows_firebase_data_source.dart
//
// FollowsFirebaseDataSource — Firebase implementation of FollowsRemoteDataSource.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'follows_remote_data_source.dart';

/// Firebase-backed implementation of [FollowsRemoteDataSource].
///
/// All mutating operations (follow/unfollow) use a [WriteBatch] for atomicity.
class FollowsFirebaseDataSource implements FollowsRemoteDataSource {
  /// Creates a [FollowsFirebaseDataSource].
  FollowsFirebaseDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Document ID for a follow relationship between [followerId] and [followeeId].
  String _docId(String followerId, String followeeId) =>
      '${followerId}_$followeeId';

  @override
  Future<void> followUser({
    required String followerId,
    required String followeeId,
  }) async {
    final batch = _firestore.batch();

    // Write the follows document.
    final followDoc = _firestore
        .collection('follows')
        .doc(_docId(followerId, followeeId));
    batch.set(followDoc, {
      'followerId': followerId,
      'followeeId': followeeId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment followingCount on the follower's user document.
    batch.update(
      _firestore.collection('users').doc(followerId),
      {'followingCount': FieldValue.increment(1)},
    );

    // Increment followerCount on the followee's user document.
    batch.update(
      _firestore.collection('users').doc(followeeId),
      {'followerCount': FieldValue.increment(1)},
    );

    await batch.commit();
  }

  @override
  Future<void> unfollowUser({
    required String followerId,
    required String followeeId,
  }) async {
    final batch = _firestore.batch();

    // Delete the follows document.
    final followDoc = _firestore
        .collection('follows')
        .doc(_docId(followerId, followeeId));
    batch.delete(followDoc);

    // Decrement followingCount on the follower's user document.
    batch.update(
      _firestore.collection('users').doc(followerId),
      {'followingCount': FieldValue.increment(-1)},
    );

    // Decrement followerCount on the followee's user document.
    batch.update(
      _firestore.collection('users').doc(followeeId),
      {'followerCount': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  @override
  Future<bool> isFollowing({
    required String followerId,
    required String followeeId,
  }) async {
    final doc = await _firestore
        .collection('follows')
        .doc(_docId(followerId, followeeId))
        .get();
    return doc.exists;
  }

  @override
  Future<List<String>> getFollowedUserIds({required String followerId}) async {
    final snapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .orderBy('createdAt')
        .get();
    return snapshot.docs
        .map((d) => d.data()['followeeId'] as String)
        .toList();
  }
}
