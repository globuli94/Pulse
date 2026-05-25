// lib/features/follows/presentation/bloc/follow_bloc.dart
//
// FollowBloc — manages follow/unfollow state for a single user profile view.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/follows_repository.dart';

part 'follow_event.dart';
part 'follow_state.dart';

/// BLoC responsible for follow/unfollow interactions on [UserProfileViewScreen].
///
/// This BLoC is **screen-scoped** — it is provided inside the route builder for
/// `/profile/:uid` and must NOT be registered globally in `main.dart`.
class FollowBloc extends Bloc<FollowEvent, FollowState> {
  /// Creates a [FollowBloc].
  FollowBloc({required FollowsRepository followsRepository})
      : _followsRepository = followsRepository,
        super(const FollowInitial()) {
    on<FollowStatusCheckRequested>(_onStatusCheck);
    on<FollowRequested>(_onFollow);
    on<UnfollowRequested>(_onUnfollow);
  }

  final FollowsRepository _followsRepository;

  /// Checks whether [FollowStatusCheckRequested.followerId] currently follows
  /// [FollowStatusCheckRequested.followeeId].
  Future<void> _onStatusCheck(
    FollowStatusCheckRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());
    try {
      final following = await _followsRepository.isFollowing(
        followerId: event.followerId,
        followeeId: event.followeeId,
      );
      emit(FollowLoaded(isFollowing: following));
    } catch (e) {
      emit(FollowFailure(error: e.toString()));
    }
  }

  /// Follows [FollowRequested.followeeId] as [FollowRequested.followerId].
  Future<void> _onFollow(
    FollowRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());
    try {
      await _followsRepository.followUser(
        followerId: event.followerId,
        followeeId: event.followeeId,
      );
      emit(const FollowLoaded(isFollowing: true));
    } catch (e) {
      emit(FollowFailure(error: e.toString()));
    }
  }

  /// Unfollows [UnfollowRequested.followeeId] as [UnfollowRequested.followerId].
  Future<void> _onUnfollow(
    UnfollowRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());
    try {
      await _followsRepository.unfollowUser(
        followerId: event.followerId,
        followeeId: event.followeeId,
      );
      emit(const FollowLoaded(isFollowing: false));
    } catch (e) {
      emit(FollowFailure(error: e.toString()));
    }
  }
}
