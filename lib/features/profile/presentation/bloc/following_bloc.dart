// lib/features/profile/presentation/bloc/following_bloc.dart
//
// FollowingBloc — loads the list of users that a given user follows.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../follows/domain/repositories/follows_repository.dart';
import '../../domain/entities/user_profile.dart';

part 'following_event.dart';
part 'following_state.dart';

/// BLoC for loading the users that a profile owner follows.
///
/// Screen-scoped: provided in the `/following/:uid` route builder.
class FollowingBloc extends Bloc<FollowingEvent, FollowingState> {
  /// Creates a [FollowingBloc].
  FollowingBloc({required FollowsRepository followsRepository})
      : _followsRepository = followsRepository,
        super(const FollowingInitial()) {
    on<FollowingLoadRequested>(_onLoadRequested);
  }

  final FollowsRepository _followsRepository;

  Future<void> _onLoadRequested(
    FollowingLoadRequested event,
    Emitter<FollowingState> emit,
  ) async {
    emit(const FollowingLoading());
    try {
      final following = await _followsRepository.getFollowing(event.uid);
      emit(FollowingLoaded(following: following));
    } catch (e) {
      emit(FollowingError(message: e.toString()));
    }
  }
}
