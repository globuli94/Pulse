// lib/features/posts/presentation/bloc/posts_feed_bloc.dart
//
// PostsFeedBloc — manages the paginated posts feed.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/follows/domain/repositories/follows_repository.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';

part 'posts_feed_event.dart';
part 'posts_feed_state.dart';

/// BLoC responsible for the global posts feed.
///
/// Registered globally in `main.dart` — [FeedScreen] lives in an IndexedStack
/// and must not provide its own [PostsFeedBloc].
///
/// The feed is filtered to posts authored by [currentUserId] and all users
/// that [currentUserId] follows. This list is fetched once per subscription
/// request and stored in [PostsFeedLoaded.authorIds] for use during pagination.
class PostsFeedBloc extends Bloc<PostsFeedEvent, PostsFeedState> {
  /// Creates a [PostsFeedBloc].
  ///
  /// Provide [followsRepository] and [currentUserId] to enable the
  /// followed-user feed filter. When omitted the feed shows all posts.
  PostsFeedBloc({
    required PostsRepository repository,
    FollowsRepository? followsRepository,
    String currentUserId = '',
  })  : _repository = repository,
        _followsRepository = followsRepository,
        _currentUserId = currentUserId,
        super(const PostsFeedInitial()) {
    on<PostsFeedSubscriptionRequested>(_onSubscriptionRequested);
    on<PostsFeedNextPageRequested>(_onNextPageRequested);
    on<PostsDeleteRequested>(_onDeleteRequested);
  }

  final PostsRepository _repository;
  final FollowsRepository? _followsRepository;

  /// The authenticated user's UID used to build the author-ID filter.
  final String _currentUserId;

  /// Loads (or reloads) the first page of the feed.
  ///
  /// Fetches followed UIDs first, then requests the first page filtered to
  /// [_currentUserId] and all followed users.
  Future<void> _onSubscriptionRequested(
    PostsFeedSubscriptionRequested event,
    Emitter<PostsFeedState> emit,
  ) async {
    emit(const PostsFeedLoading());
    try {
      final List<String> authorIds;
      if (_followsRepository != null && _currentUserId.isNotEmpty) {
        final followedIds = await _followsRepository.getFollowedUserIds(
          followerId: _currentUserId,
        );
        authorIds = [_currentUserId, ...followedIds];
      } else {
        authorIds = const [];
      }
      final page = await _repository.fetchFeed(
        authorIds: authorIds.isEmpty ? null : authorIds,
      );
      emit(
        PostsFeedLoaded(
          posts: page.posts,
          authorIds: authorIds,
          hasMore: page.hasMore,
          cursor: page.cursor,
        ),
      );
    } catch (e) {
      emit(PostsFeedError(error: e.toString()));
    }
  }

  /// Appends the next page to the existing feed using the same author filter.
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
      final page = await _repository.fetchFeed(
        cursor: current.cursor,
        authorIds: current.authorIds.isEmpty ? null : current.authorIds,
      );
      emit(
        PostsFeedLoaded(
          posts: [...current.posts, ...page.posts],
          authorIds: current.authorIds,
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
