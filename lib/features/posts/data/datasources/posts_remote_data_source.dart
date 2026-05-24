// lib/features/posts/data/datasources/posts_remote_data_source.dart
//
// PostsRemoteDataSource — abstract interface for the posts data source.

import 'package:image_picker/image_picker.dart';

/// Abstract interface that all posts remote data sources must implement.
abstract class PostsRemoteDataSource {
  /// Returns a stream of raw post data maps ordered by creation time.
  Stream<List<Map<String, dynamic>>> watchFeed();

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
}
