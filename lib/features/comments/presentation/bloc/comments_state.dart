// lib/features/comments/presentation/bloc/comments_state.dart
//
// CommentsState — states for CommentsBloc.

part of 'comments_bloc.dart';

/// Base class for all comments states.
abstract class CommentsState {
  const CommentsState();
}

/// Initial state before any subscription is started.
class CommentsInitial extends CommentsState {
  const CommentsInitial();
}

/// Waiting for the first snapshot from Firestore.
class CommentsLoading extends CommentsState {
  const CommentsLoading();
}

/// Comments loaded successfully.
class CommentsLoaded extends CommentsState {
  const CommentsLoaded({required this.comments});

  final List<Comment> comments;
}

/// An error occurred while loading comments.
class CommentsError extends CommentsState {
  const CommentsError({required this.message});

  final String message;
}
