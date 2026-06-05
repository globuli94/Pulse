// lib/features/comments/data/datasources/comments_firebase_data_source.dart
//
// CommentsFirebaseDataSource — Firestore implementation.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'comments_remote_data_source.dart';

/// Firestore-backed implementation of [CommentsRemoteDataSource].
class CommentsFirebaseDataSource implements CommentsRemoteDataSource {
  /// Creates a [CommentsFirebaseDataSource].
  CommentsFirebaseDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Map<String, dynamic>>> watchComments({required String postId}) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  @override
  Stream<int> watchCommentCount(String postId) {
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String text,
  }) async {
    final commentRef = _firestore.collection('comments').doc();
    final batch = _firestore.batch();

    batch.set(commentRef, {
      'postId': postId,
      'authorId': authorId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final postOwnerUid = postDoc.data()?['userId'] as String?;

    if (postOwnerUid != null && postOwnerUid != authorId) {
      final authorDoc =
          await _firestore.collection('users').doc(authorId).get();
      final actorDisplayName =
          authorDoc.data()?['displayName'] as String? ?? '';

      final notificationRef = _firestore.collection('notifications').doc();
      batch.set(notificationRef, {
        'userId': postOwnerUid,
        'type': 'comment',
        'actorId': authorId,
        'actorDisplayName': actorDisplayName,
        'postId': postId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
