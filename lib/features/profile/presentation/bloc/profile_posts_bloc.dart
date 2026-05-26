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
/// Registered globally in `main.dart`. Dispatch [ProfilePostsLoadRequested]
/// with the viewed user's UID whenever the profile screen is shown.
class ProfilePostsBloc extends Bloc<ProfilePostsEvent, ProfilePostsState> {
  /// Creates a [ProfilePostsBloc].
  ProfilePostsBloc({required PostsRepository postsRepository})
      : _postsRepository = postsRepository,
        super(const ProfilePostsInitial()) {
    on<ProfilePostsLoadRequested>(_onLoadRequested);
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
}
