// lib/features/profile/presentation/bloc/profile_posts_bloc.dart
//
// ProfilePostsBloc — manages the list of posts for a user's profile.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../posts/domain/entities/post.dart';
import '../../../posts/domain/repositories/posts_repository.dart';

part 'profile_posts_event.dart';
part 'profile_posts_state.dart';

/// BLoC responsible for loading and displaying a user's posts on their profile.
///
/// Registered globally in `main.dart`. Dispatch
/// [ProfilePostsSubscriptionRequested] with the authenticated user's UID to
/// start a live Firestore stream that updates whenever posts are added or
/// deleted. [ProfilePostsLoadRequested] remains available for one-shot fetches.
class ProfilePostsBloc extends Bloc<ProfilePostsEvent, ProfilePostsState> {
  /// Creates a [ProfilePostsBloc].
  ProfilePostsBloc({required PostsRepository postsRepository})
      : _postsRepository = postsRepository,
        super(const ProfilePostsInitial()) {
    on<ProfilePostsLoadRequested>(_onLoadRequested);
    on<ProfilePostsSubscriptionRequested>(_onSubscriptionRequested);
  }

  final PostsRepository _postsRepository;

  Future<void> _onLoadRequested(
    ProfilePostsLoadRequested event,
    Emitter<ProfilePostsState> emit,
  ) async {
    emit(const ProfilePostsLoading());
    try {
      final posts = await _postsRepository.getPostsByUser(event.uid);
      emit(ProfilePostsLoaded(posts: posts));
    } catch (e) {
      emit(ProfilePostsError(message: e.toString()));
    }
  }

  Future<void> _onSubscriptionRequested(
    ProfilePostsSubscriptionRequested event,
    Emitter<ProfilePostsState> emit,
  ) async {
    emit(const ProfilePostsLoading());
    await emit.forEach(
      _postsRepository.watchPostsByUser(event.uid),
      onData: (posts) => ProfilePostsLoaded(posts: posts),
      onError: (e, _) => ProfilePostsError(message: e.toString()),
    );
  }
}
