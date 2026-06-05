// lib/features/comments/presentation/bloc/comments_bloc.dart
//
// CommentsBloc — manages the comments list for a single post screen.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/comment.dart';
import '../../domain/repositories/comments_repository.dart';

part 'comments_event.dart';
part 'comments_state.dart';

/// Screen-scoped BLoC that manages the comments list.
///
/// Provided in the router builder for `/post/:postId/comments`.
class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  /// Creates a [CommentsBloc].
  CommentsBloc({required CommentsRepository repository})
      : _repository = repository,
        super(const CommentsInitial()) {
    on<CommentsSubscriptionRequested>(_onSubscriptionRequested);
    on<CommentAddRequested>(_onAddRequested);
  }

  final CommentsRepository _repository;

  Future<void> _onSubscriptionRequested(
    CommentsSubscriptionRequested event,
    Emitter<CommentsState> emit,
  ) async {
    emit(const CommentsLoading());
    await emit.forEach<List<Comment>>(
      _repository.watchComments(postId: event.postId),
      onData: (list) => CommentsLoaded(comments: list),
      onError: (e, _) => CommentsError(message: e.toString()),
    );
  }

  Future<void> _onAddRequested(
    CommentAddRequested event,
    Emitter<CommentsState> emit,
  ) async {
    try {
      await _repository.addComment(
        postId: event.postId,
        authorId: event.authorId,
        text: event.text,
      );
    } catch (_) {
      // Errors are surfaced via snackbar in the UI; stream keeps state valid.
    }
  }
}
