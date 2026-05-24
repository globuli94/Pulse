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
  }) async {
    // Fetch one extra document to determine whether another page exists.
    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit + 1);

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
