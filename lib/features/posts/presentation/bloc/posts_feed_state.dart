// lib/features/posts/presentation/bloc/posts_feed_state.dart
//
// PostsFeedState — states for PostsFeedBloc.

part of 'posts_feed_bloc.dart';

/// Base class for all PostsFeedBloc states.
sealed class PostsFeedState {
  const PostsFeedState();
}

/// Initial state before any subscription has been requested.
final class PostsFeedInitial extends PostsFeedState {
  const PostsFeedInitial();
}

/// Stream subscription has been requested; waiting for first snapshot.
final class PostsFeedLoading extends PostsFeedState {
  const PostsFeedLoading();
}

/// Feed data is available.
final class PostsFeedLoaded extends PostsFeedState {
  const PostsFeedLoaded({
    required this.posts,
    this.hasMore = false,
    this.cursor,
    this.isLoadingMore = false,
  });

  /// All posts loaded so far (accumulated across pages).
  final List<Post> posts;

  /// Whether another page of posts is available.
  final bool hasMore;

  /// Opaque cursor for the next page; null when no more pages exist.
  final Object? cursor;

  /// True while the next page is being fetched.
  final bool isLoadingMore;

  PostsFeedLoaded copyWith({bool? isLoadingMore}) {
    return PostsFeedLoaded(
      posts: posts,
      hasMore: hasMore,
      cursor: cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// An error occurred while subscribing to or loading the feed.
final class PostsFeedError extends PostsFeedState {
  const PostsFeedError({required this.error});

  final String error;
}
