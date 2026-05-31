// lib/features/posts/data/datasources/posts_firebase_data_source.dart
//
// PostsFirebaseDataSource — Firebase implementation of PostsRemoteDataSource.

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/posts_feed_raw_page.dart';
import 'posts_remote_data_source.dart';

/// Firebase-backed implementation of [PostsRemoteDataSource].
class PostsFirebaseDataSource implements PostsRemoteDataSource {
  /// Creates a [PostsFirebaseDataSource].
  PostsFirebaseDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Stream<List<Map<String, dynamic>>> watchFeed() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  @override
  Future<PostsFeedRawPage> fetchFeed({
    DocumentSnapshot? cursor,
    int limit = 15,
    List<String>? authorIds,
  }) async {
    // Firestore `in` query limit is 30 items. Assert in debug; clamp in release.
    final filteredAuthorIds =
        (authorIds != null && authorIds.isNotEmpty) ? authorIds : null;
    assert(
      filteredAuthorIds == null || filteredAuthorIds.length <= 30,
      'authorIds must contain at most 30 items (Firestore in-query limit).',
    );
    final clampedIds = filteredAuthorIds != null &&
            filteredAuthorIds.length > 30
        ? filteredAuthorIds.take(30).toList()
        : filteredAuthorIds;

    // Fetch one extra document to determine whether another page exists.
    Query<Map<String, dynamic>> query = _firestore.collection('posts');

    if (clampedIds != null) {
      // Apply author filter before orderBy to satisfy Firestore index rules.
      query = query.where('userId', whereIn: clampedIds);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit + 1);

    if (cursor != null) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final hasMore = snapshot.docs.length > limit;
    final docs =
        hasMore ? snapshot.docs.take(limit).toList() : snapshot.docs;

    return PostsFeedRawPage(
      posts: docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList(),
      hasMore: hasMore,
      cursor: docs.isNotEmpty ? docs.last : null,
    );
  }

  @override
  Future<void> createPost({
    required String text,
    required String userId,
    required String displayName,
    String? avatarUrl,
    XFile? image,
  }) async {
    final docRef = _firestore.collection('posts').doc();
    final postId = docRef.id;

    String? imageUrl;
    if (image != null) {
      final ref =
          _storage.ref().child('posts/$userId/$postId/image');
      await ref.putFile(File(image.path));
      imageUrl = await ref.getDownloadURL();
    }

    final data = <String, dynamic>{
      'userId': userId,
      'displayName': displayName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (imageUrl != null) data['imageUrl'] = imageUrl;

    await docRef.set(data);
  }

  @override
  Future<List<Map<String, dynamic>>> getPostsByUser(String uid) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> watchPostsByUser(String uid) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  @override
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    final likeId = '${userId}_$postId';

    // Read post and actor docs to build the notification.
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    final postOwnerUid = postDoc.data()?['userId'] as String?;
    final actorDoc = await _firestore.collection('users').doc(userId).get();
    final actorData = actorDoc.data() ?? {};
    final actorDisplayName = actorData['displayName'] as String? ?? '';
    final actorPhotoUrl = actorData['photoUrl'] as String?;

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('likes').doc(likeId),
      {
        'postId': postId,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(
      _firestore.collection('posts').doc(postId),
      {'likeCount': FieldValue.increment(1)},
    );

    // Write a like notification for the post owner (skip self-likes).
    if (postOwnerUid != null && postOwnerUid != userId) {
      final notifRef = _firestore.collection('notifications').doc();
      final notifData = <String, dynamic>{
        'id': notifRef.id,
        'userId': postOwnerUid,
        'type': 'like',
        'actorId': userId,
        'actorDisplayName': actorDisplayName,
        'postId': postId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (actorPhotoUrl != null) notifData['actorPhotoUrl'] = actorPhotoUrl;
      batch.set(notifRef, notifData);
    }

    await batch.commit();
  }

  @override
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    final likeId = '${userId}_$postId';
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('likes').doc(likeId));
    batch.update(
      _firestore.collection('posts').doc(postId),
      {'likeCount': FieldValue.increment(-1)},
    );
    await batch.commit();
  }

  @override
  Future<bool> isLiked({
    required String postId,
    required String userId,
  }) async {
    final likeId = '${userId}_$postId';
    final doc = await _firestore.collection('likes').doc(likeId).get();
    return doc.exists;
  }

  @override
  Stream<bool> watchIsLiked({
    required String postId,
    required String userId,
  }) {
    final likeId = '${userId}_$postId';
    return _firestore
        .collection('likes')
        .doc(likeId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Stream<int> watchLikeCount(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) => (doc.data()?['likeCount'] as num?)?.toInt() ?? 0);
  }

  @override
  Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    final docRef = _firestore.collection('posts').doc(postId);
    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data();
      final imageUrl = data?['imageUrl'] as String?;
      if (imageUrl != null) {
        try {
          final ref =
              _storage.ref().child('posts/$userId/$postId/image');
          await ref.delete();
        } on FirebaseException catch (e) {
          if (e.code != 'object-not-found') rethrow;
        }
      }
    }

    await docRef.delete();
  }
}
