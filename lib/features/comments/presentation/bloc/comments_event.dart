// lib/features/comments/presentation/bloc/comments_event.dart
//
// CommentsEvent — events for CommentsBloc.

part of 'comments_bloc.dart';

/// Base class for all comments events.
abstract class CommentsEvent {
  const CommentsEvent();
}

/// Requests the real-time comments stream for [postId].
class CommentsSubscriptionRequested extends CommentsEvent {
  /// Creates a [CommentsSubscriptionRequested].
  const CommentsSubscriptionRequested({required this.postId});

  final String postId;
}

/// Requests that a new comment is added.
class CommentAddRequested extends CommentsEvent {
  /// Creates a [CommentAddRequested].
  const CommentAddRequested({
    required this.postId,
    required this.authorId,
    required this.text,
  });

  final String postId;
  final String authorId;
  final String text;
}
