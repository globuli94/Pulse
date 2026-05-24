// lib/features/posts/domain/repositories/posts_repository.dart
//
// PostsRepository — abstract repository interface for posts.

import 'package:image_picker/image_picker.dart';

import '../entities/post.dart';

/// Abstract repository defining all post-related operations.
///
/// Zero Firebase imports — implementations live in the data layer.
abstract class PostsRepository {
  /// Returns a stream of all posts ordered by creation time (newest first).
  Stream<List<Post>> watchFeed();

  /// Creates a new post authored by [userId].
  ///
  /// If [image] is provided it will be uploaded to Firebase Storage before
  /// the Firestore document is written.
  Future<void> createPost({
    required String text,
    required String userId,
    required String displayName,
    String? avatarUrl,
    XFile? image,
  });

  /// Deletes the post identified by [postId].
  ///
  /// If the post has an associated image it is also removed from Storage.
  Future<void> deletePost({required String postId, required String userId});
}
