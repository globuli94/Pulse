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
    required this.displayName,
    this.avatarUrl,
    required this.text,
    this.imageUrl,
    required this.createdAt,
  });

  /// Firestore document ID.
  final String id;

  /// Firebase Auth UID of the post author.
  final String userId;

  /// Author's display name captured at post time.
  final String displayName;

  /// Author's avatar URL captured at post time; null if no avatar.
  final String? avatarUrl;

  /// Post body text.
  final String text;

  /// Download URL for the post image; null if no image.
  final String? imageUrl;

  /// Creation timestamp.
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        userId,
        displayName,
        avatarUrl,
        text,
        imageUrl,
        createdAt,
      ];
}
