// lib/features/posts/domain/repositories/posts_repository.dart
//
// PostsRepository — abstract repository interface for posts.

import 'package:image_picker/image_picker.dart';

import '../entities/post.dart';
import '../entities/posts_feed_page.dart';

/// Abstract repository defining all post-related operations.
///
/// Zero Firebase imports — implementations live in the data layer.
abstract class PostsRepository {
  /// Returns a stream of all posts ordered by creation time (newest first).
  Stream<List<Post>> watchFeed();

  /// Fetches a single page of posts ordered by [createdAt] descending.
  ///
  /// Pass [cursor] returned by a previous [fetchFeed] call to load the next
  /// page. The cursor is opaque to the domain layer — only the data layer
  /// knows its concrete type.
  ///
  /// When [authorIds] is non-null and non-empty, only posts whose `userId` is
  /// in the list are returned. Pass `null` or an empty list to get all posts.
  Future<PostsFeedPage> fetchFeed({
    Object? cursor,
    int limit = 15,
    List<String>? authorIds,
  });

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

  /// Fetches up to 20 posts authored by [uid], newest first.
  ///
  /// Requires a Firestore composite index on `posts(userId ASC, createdAt DESC)`.
  Future<List<Post>> getPostsByUser(String uid);

  /// Returns a live stream of up to 20 posts authored by [uid], newest first.
  ///
  /// Uses the same Firestore composite index as [getPostsByUser].
  Stream<List<Post>> watchPostsByUser(String uid);

  /// Likes the post [postId] on behalf of [userId].
  ///
  /// Writes `likes/{userId}_{postId}` and increments `posts/{postId}.likeCount`.
  Future<void> likePost({required String postId, required String userId});

  /// Unlikes the post [postId] on behalf of [userId].
  ///
  /// Deletes `likes/{userId}_{postId}` and decrements `posts/{postId}.likeCount`.
  Future<void> unlikePost({required String postId, required String userId});

  /// Returns true if [userId] has liked [postId].
  ///
  /// Single-document read: `likes/{userId}_{postId}`.
  Future<bool> isLiked({required String postId, required String userId});

  /// Real-time stream: emits `true` when [userId] has liked [postId], `false`
  /// when they have not. Watches `likes/{userId}_{postId}` existence.
  Stream<bool> watchIsLiked({required String postId, required String userId});

  /// Real-time stream of the `likeCount` field on `posts/{postId}`.
  Stream<int> watchLikeCount(String postId);
}
