// lib/features/posts/data/models/posts_feed_raw_page.dart
//
// PostsFeedRawPage — raw paginated result from the Firebase data source.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw result returned by [PostsRemoteDataSource.fetchFeed].
///
/// The [cursor] is the last [DocumentSnapshot] in this page and is passed
/// to the next [PostsRemoteDataSource.fetchFeed] call via
/// [PostsRepositoryImpl] as an opaque [Object?] at the domain boundary.
class PostsFeedRawPage {
  /// Creates a [PostsFeedRawPage].
  const PostsFeedRawPage({
    required this.posts,
    required this.hasMore,
    this.cursor,
  });

  /// Raw post data maps for this page.
  final List<Map<String, dynamic>> posts;

  /// Whether another page is available.
  final bool hasMore;

  /// Firestore cursor pointing to the last document in this page.
  final DocumentSnapshot? cursor;
}
