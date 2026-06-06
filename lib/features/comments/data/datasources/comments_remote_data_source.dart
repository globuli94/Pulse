// lib/features/comments/data/datasources/comments_remote_data_source.dart
//
// CommentsRemoteDataSource — abstract interface for raw comment data access.

/// Abstract interface for remote comment data access (raw maps).
abstract class CommentsRemoteDataSource {
  /// Real-time stream of raw comment maps for [postId], oldest first.
  Stream<List<Map<String, dynamic>>> watchComments({required String postId});

  /// Real-time stream of the comment count for [postId].
  Stream<int> watchCommentCount(String postId);

  /// Creates a new comment. Writes notification if [authorId] != post owner.
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String text,
  });
}
