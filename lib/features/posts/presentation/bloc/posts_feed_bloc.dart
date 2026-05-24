// lib/features/posts/presentation/bloc/posts_feed_bloc.dart
//
// PostsFeedBloc — manages the paginated posts feed.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';

part 'posts_feed_event.dart';
part 'posts_feed_state.dart';

/// BLoC responsible for the global posts feed.
///
/// Registered globally in `main.dart` — [FeedScreen] lives in an IndexedStack
/// and must not provide its own [PostsFeedBloc].
class PostsFeedBloc extends Bloc<PostsFeedEvent, PostsFeedState> {
  /// Creates a [PostsFeedBloc].
  PostsFeedBloc({required PostsRepository repository})
      : _repository = repository,
        super(const PostsFeedInitial()) {
    on<PostsFeedSubscriptionRequested>(_onSubscriptionRequested);
    on<PostsFeedNextPageRequested>(_onNextPageRequested);
    on<PostsDeleteRequested>(_onDeleteRequested);
  }

  final PostsRepository _repository;

  /// Loads (or reloads) the first page of the feed.
  Future<void> _onSubscriptionRequested(
    PostsFeedSubscriptionRequested event,
    Emitter<PostsFeedState> emit,
  ) async {
    emit(const PostsFeedLoading());
    try {
      final page = await _repository.fetchFeed();
      emit(
        PostsFeedLoaded(
          posts: page.posts,
          hasMore: page.hasMore,
          cursor: page.cursor,
        ),
      );
    } catch (e) {
      emit(PostsFeedError(error: e.toString()));
    }
  }

  /// Appends the next page to the existing feed.
  Future<void> _onNextPageRequested(
    PostsFeedNextPageRequested event,
    Emitter<PostsFeedState> emit,
  ) async {
    final current = state;
    if (current is! PostsFeedLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.fetchFeed(cursor: current.cursor);
      emit(
        PostsFeedLoaded(
          posts: [...current.posts, ...page.posts],
          hasMore: page.hasMore,
          cursor: page.cursor,
        ),
      );
    } catch (e) {
      emit(PostsFeedError(error: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    PostsDeleteRequested event,
    Emitter<PostsFeedState> emit,
  ) async {
    try {
      await _repository.deletePost(
        postId: event.postId,
        userId: event.userId,
      );
      // Reload first page so the deleted post disappears immediately.
      add(const PostsFeedSubscriptionRequested());
    } catch (e) {
      emit(PostsFeedError(error: e.toString()));
    }
  }
}
