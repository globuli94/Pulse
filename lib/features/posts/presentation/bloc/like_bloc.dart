// lib/features/posts/presentation/bloc/like_bloc.dart
//
// LikeBloc — manages per-item like/unlike state for a single PostCard.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/posts_repository.dart';
import 'like_event.dart';
import 'like_state.dart';

/// Per-item BLoC that manages the like state for a single post.
///
/// Must be provided by [PostCard] (the parent), not globally in main.dart.
///
/// On [LikeInitialised], subscribes to real-time streams for both `isLiked`
/// and `likeCount` so that changes made on other screens are reflected
/// immediately without a manual refresh.
class LikeBloc extends Bloc<LikeEvent, LikeState> {
  LikeBloc({required PostsRepository repository})
      : _repository = repository,
        super(const LikeInitial()) {
    on<LikeInitialised>(_onInitialised);
    on<LikeToggleRequested>(_onToggleRequested);
  }

  final PostsRepository _repository;

  /// Subscribes to [watchIsLiked] and [watchLikeCount] concurrently by merging
  /// both streams into a single [StreamController].  The handler keeps running
  /// (via [emit.forEach]) until the BLoC is closed, mirroring the real-time
  /// pattern used by [PostsFeedBloc] and [NotificationsBloc].
  Future<void> _onInitialised(
    LikeInitialised event,
    Emitter<LikeState> emit,
  ) async {
    emit(const LikeLoading());

    bool? latestIsLiked;
    var latestCount = event.initialLikeCount;

    // Broadcast controller so emit.forEach can subscribe without ordering
    // constraints relative to the two upstream subscriptions.
    final mergeController = StreamController<LikeLoaded>.broadcast();

    final isLikedSub = _repository
        .watchIsLiked(postId: event.postId, userId: event.userId)
        .listen(
      (isLiked) {
        latestIsLiked = isLiked;
        mergeController.add(
          LikeLoaded(isLiked: isLiked, likeCount: latestCount),
        );
      },
      onError: mergeController.addError,
      cancelOnError: false,
    );

    final countSub = _repository.watchLikeCount(event.postId).listen(
      (count) {
        latestCount = count;
        // Only emit once isLiked has been received at least once.
        if (latestIsLiked != null) {
          mergeController.add(
            LikeLoaded(isLiked: latestIsLiked!, likeCount: count),
          );
        }
      },
      onError: mergeController.addError,
      cancelOnError: false,
    );

    try {
      await emit.forEach<LikeLoaded>(
        mergeController.stream,
        onData: (s) => s,
        onError: (e, _) => LikeError(message: e.toString()),
      );
    } finally {
      await isLikedSub.cancel();
      await countSub.cancel();
      await mergeController.close();
    }
  }

  Future<void> _onToggleRequested(
    LikeToggleRequested event,
    Emitter<LikeState> emit,
  ) async {
    final current = state;
    if (current is! LikeLoaded) return;
    // Optimistic update — stream confirms or corrects within milliseconds.
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
      // Rollback on failure; stream will also re-emit the server state.
      emit(LikeLoaded(
        isLiked: current.isLiked,
        likeCount: current.likeCount,
      ));
    }
  }
}
