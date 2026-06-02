// lib/features/posts/domain/entities/post.dart
//
// Post — pure Dart domain entity representing a feed post.

import 'package:equatable/equatable.dart';

/// Represents a single post in the Pulse feed.
///
/// Zero Firebase imports — this is a pure domain entity.
class Post extends Equatable {
  /// Creates a [Post].
  const Post({
    required this.id,
    required this.userId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    this.likeCount = 0,
  });

  /// Firestore document ID.
  final String id;

  /// Firebase Auth UID of the post author.
  final String userId;

  /// Post body text.
  final String text;

  /// Download URL for the post image; null if no image.
  final String? imageUrl;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Number of likes this post has received.
  final int likeCount;

  @override
  List<Object?> get props => [
        id,
        userId,
        text,
        imageUrl,
        createdAt,
        likeCount,
      ];
}
