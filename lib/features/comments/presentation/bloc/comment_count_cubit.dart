// lib/features/comments/presentation/bloc/comment_count_cubit.dart
//
// CommentCountCubit — tracks the real-time comment count for a single post.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/comments_repository.dart';

/// Per-post cubit that emits the real-time comment count.
///
/// Must be provided per PostCard (not globally), keyed by post ID.
class CommentCountCubit extends Cubit<int> {
  /// Creates a [CommentCountCubit].
  CommentCountCubit({required CommentsRepository repository})
      : _repository = repository,
        super(0);

  final CommentsRepository _repository;
  StreamSubscription<int>? _subscription;

  /// Starts (or restarts) watching the comment count for [postId].
  void startWatching(String postId) {
    _subscription?.cancel();
    _subscription = _repository.watchCommentCount(postId).listen(
      emit,
      onError: (_) => emit(0),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
