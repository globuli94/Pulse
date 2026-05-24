// lib/features/posts/presentation/bloc/posts_feed_bloc.dart
//
// PostsFeedBloc — manages the global posts feed stream.

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
    on<PostsDeleteRequested>(_onDeleteRequested);
  }

  final PostsRepository _repository;

  Future<void> _onSubscriptionRequested(
    PostsFeedSubscriptionRequested event,
    Emitter<PostsFeedState> emit,
  ) async {
    emit(const PostsFeedLoading());
    await emit.forEach<List<Post>>(
      _repository.watchFeed(),
      onData: (posts) => PostsFeedLoaded(posts: posts),
      onError: (error, _) => PostsFeedError(error: error.toString()),
    );
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
      // Stream auto-refreshes; no manual state update needed.
    } catch (e) {
      emit(PostsFeedError(error: e.toString()));
    }
  }
}
