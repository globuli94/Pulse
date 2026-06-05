// lib/features/comments/domain/entities/comment.dart
//
// Comment — domain entity for a single post comment.

import 'package:equatable/equatable.dart';

/// A single comment on a post.
class Comment extends Equatable {
  /// Creates a [Comment].
  const Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String text;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, postId, authorId, text, createdAt];
}
