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
    // Read the actor's user doc to build the notification.
    final actorDoc =
        await _firestore.collection('users').doc(followerId).get();
    final actorData = actorDoc.data() ?? {};
    final actorDisplayName = actorData['displayName'] as String? ?? '';
    final actorPhotoUrl = actorData['photoUrl'] as String?;

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

    // Write a follow notification for the followee (guard against self-follow).
    if (followerId != followeeId) {
      final notifRef = _firestore.collection('notifications').doc();
      final notifData = <String, dynamic>{
        'id': notifRef.id,
        'userId': followeeId,
        'type': 'follow',
        'actorId': followerId,
        'actorDisplayName': actorDisplayName,
        'postId': null,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (actorPhotoUrl != null) notifData['actorPhotoUrl'] = actorPhotoUrl;
      batch.set(notifRef, notifData);
    }

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

  @override
  Future<List<Map<String, dynamic>>> getFollowers(String uid) async {
    final followsSnapshot = await _firestore
        .collection('follows')
        .where('followeeId', isEqualTo: uid)
        .get();
    final followerIds = followsSnapshot.docs
        .map((d) => d.data()['followerId'] as String)
        .toList();
    if (followerIds.isEmpty) return [];
    final userFutures = followerIds.map(
      (id) => _firestore.collection('users').doc(id).get(),
    );
    final userDocs = await Future.wait(userFutures);
    return userDocs
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) => <String, dynamic>{'uid': doc.id, ...doc.data()!})
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getFollowing(String uid) async {
    final followsSnapshot = await _firestore
        .collection('follows')
        .where('followerId', isEqualTo: uid)
        .get();
    final followeeIds = followsSnapshot.docs
        .map((d) => d.data()['followeeId'] as String)
        .toList();
    if (followeeIds.isEmpty) return [];
    final userFutures = followeeIds.map(
      (id) => _firestore.collection('users').doc(id).get(),
    );
    final userDocs = await Future.wait(userFutures);
    return userDocs
        .where((doc) => doc.exists && doc.data() != null)
        .map((doc) => <String, dynamic>{'uid': doc.id, ...doc.data()!})
        .toList();
  }
}
