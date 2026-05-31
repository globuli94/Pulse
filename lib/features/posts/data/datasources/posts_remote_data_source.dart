// lib/features/posts/data/datasources/posts_remote_data_source.dart
//
// PostsRemoteDataSource — abstract interface for the posts data source.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/posts_feed_raw_page.dart';

/// Abstract interface that all posts remote data sources must implement.
abstract class PostsRemoteDataSource {
  /// Returns a stream of raw post data maps ordered by creation time.
  Stream<List<Map<String, dynamic>>> watchFeed();

  /// Fetches a single page of posts ordered by [createdAt] descending.
  ///
  /// Pass [cursor] (the [DocumentSnapshot] from a previous page) to continue
  /// pagination. Omit [cursor] to start from the first page.
  ///
  /// When [authorIds] is non-null and non-empty, only posts whose `userId` is
  /// in the list are returned. Firestore `in` queries are limited to 30 items.
  Future<PostsFeedRawPage> fetchFeed({
    DocumentSnapshot? cursor,
    int limit = 15,
    List<String>? authorIds,
  });

  /// Creates a new post document and optionally uploads an image.
  ///
  /// Returns the download URL of the uploaded image, or null if no image
  /// was provided.
  Future<void> createPost({
    required String text,
    required String userId,
    required String displayName,
    String? avatarUrl,
    XFile? image,
  });

  /// Deletes the Firestore document and its associated Storage image (if any).
  Future<void> deletePost({required String postId, required String userId});

  /// Fetches up to 20 posts by [uid], ordered by createdAt descending.
  Future<List<Map<String, dynamic>>> getPostsByUser(String uid);

  /// Returns a live stream of posts by [uid], ordered by createdAt descending.
  Stream<List<Map<String, dynamic>>> watchPostsByUser(String uid);

  Future<void> likePost({required String postId, required String userId});
  Future<void> unlikePost({required String postId, required String userId});
  Future<bool> isLiked({required String postId, required String userId});

  /// Real-time stream: emits `true` when [userId] has liked [postId], `false`
  /// when they have not. Watches `likes/{userId}_{postId}` existence.
  Stream<bool> watchIsLiked({required String postId, required String userId});

  /// Real-time stream of the `likeCount` field on `posts/{postId}`.
  Stream<int> watchLikeCount(String postId);
}
