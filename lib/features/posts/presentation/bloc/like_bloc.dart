// lib/features/posts/presentation/bloc/like_bloc.dart
//
// LikeBloc — manages per-item like/unlike state for a single PostCard.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/posts_repository.dart';
import 'like_event.dart';
import 'like_state.dart';

/// Per-item BLoC that manages the like state for a single post.
///
/// Must be provided by [PostCard] (the parent), not globally in main.dart.
class LikeBloc extends Bloc<LikeEvent, LikeState> {
  LikeBloc({required PostsRepository repository})
      : _repository = repository,
        super(const LikeInitial()) {
    on<LikeInitialised>(_onInitialised);
    on<LikeToggleRequested>(_onToggleRequested);
  }

  final PostsRepository _repository;

  Future<void> _onInitialised(
    LikeInitialised event,
    Emitter<LikeState> emit,
  ) async {
    emit(const LikeLoading());
    try {
      final liked = await _repository.isLiked(
        postId: event.postId,
        userId: event.userId,
      );
      emit(LikeLoaded(isLiked: liked, likeCount: event.initialLikeCount));
    } catch (e) {
      emit(LikeError(message: e.toString()));
    }
  }

  Future<void> _onToggleRequested(
    LikeToggleRequested event,
    Emitter<LikeState> emit,
  ) async {
    final current = state;
    if (current is! LikeLoaded) return;
    // Optimistic update
    final newIsLiked = !current.isLiked;
    final newCount =
        newIsLiked ? current.likeCount + 1 : current.likeCount - 1;
    emit(LikeLoaded(isLiked: newIsLiked, likeCount: newCount));
    try {
      if (newIsLiked) {
        await _repository.likePost(
          postId: event.postId,
          userId: event.userId,
        );
      } else {
        await _repository.unlikePost(
          postId: event.postId,
          userId: event.userId,
        );
      }
    } catch (e) {
      // Rollback on failure
      emit(LikeLoaded(
        isLiked: current.isLiked,
        likeCount: current.likeCount,
      ));
    }
  }
}
