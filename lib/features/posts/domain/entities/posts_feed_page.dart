// lib/features/posts/domain/entities/posts_feed_page.dart
//
// PostsFeedPage — domain model for a single page of the paginated feed.

import 'post.dart';

/// Holds one page of feed results plus the information needed to fetch the
/// next page.
///
/// [cursor] is an opaque value supplied by the repository implementation;
/// callers pass it back to [PostsRepository.fetchFeed] to load the next page.
/// The domain layer never inspects or casts this value.
class PostsFeedPage {
  /// Creates a [PostsFeedPage].
  const PostsFeedPage({
    required this.posts,
    required this.hasMore,
    this.cursor,
  });

  /// Posts for this page.
  final List<Post> posts;

  /// Whether another page is available after this one.
  final bool hasMore;

  /// Opaque cursor for the next page; null when there is no next page.
  final Object? cursor;
}
