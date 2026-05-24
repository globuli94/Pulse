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
  const PostsFeedLoaded({required this.posts});

  final List<Post> posts;
}

/// An error occurred while subscribing to or loading the feed.
final class PostsFeedError extends PostsFeedState {
  const PostsFeedError({required this.error});

  final String error;
}
