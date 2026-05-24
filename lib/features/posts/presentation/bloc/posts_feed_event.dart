// lib/features/posts/presentation/bloc/posts_feed_event.dart
//
// PostsFeedEvent — events for PostsFeedBloc.

part of 'posts_feed_bloc.dart';

/// Base class for all PostsFeedBloc events.
sealed class PostsFeedEvent {
  const PostsFeedEvent();
}

/// Requests an active subscription to the posts feed stream.
final class PostsFeedSubscriptionRequested extends PostsFeedEvent {
  const PostsFeedSubscriptionRequested();
}

/// Requests deletion of a post.
final class PostsDeleteRequested extends PostsFeedEvent {
  const PostsDeleteRequested({
    required this.postId,
    required this.userId,
  });

  final String postId;
  final String userId;
}
