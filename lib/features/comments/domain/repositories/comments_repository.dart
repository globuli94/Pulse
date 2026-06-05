// lib/features/comments/domain/repositories/comments_repository.dart
//
// CommentsRepository — abstract interface for comment operations.

import '../entities/comment.dart';

/// Abstract interface for comment data access.
abstract class CommentsRepository {
  /// Real-time stream of all comments for [postId], oldest first.
  Stream<List<Comment>> watchComments({required String postId});

  /// Real-time stream of the comment count for [postId].
  Stream<int> watchCommentCount(String postId);

  /// Creates a new comment. Writes notification if [authorId] != post owner.
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String text,
  });
}
