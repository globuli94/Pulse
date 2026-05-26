// lib/features/profile/presentation/bloc/followers_bloc.dart
//
// FollowersBloc — loads the list of followers for a given user.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../follows/domain/repositories/follows_repository.dart';
import '../../domain/entities/user_profile.dart';

part 'followers_event.dart';
part 'followers_state.dart';

/// BLoC for loading followers of a user profile.
///
/// Screen-scoped: provided in the `/followers/:uid` route builder.
class FollowersBloc extends Bloc<FollowersEvent, FollowersState> {
  /// Creates a [FollowersBloc].
  FollowersBloc({required FollowsRepository followsRepository})
      : _followsRepository = followsRepository,
        super(const FollowersInitial()) {
    on<FollowersLoadRequested>(_onLoadRequested);
  }

  final FollowsRepository _followsRepository;

  Future<void> _onLoadRequested(
    FollowersLoadRequested event,
    Emitter<FollowersState> emit,
  ) async {
    emit(const FollowersLoading());
    try {
      final followers = await _followsRepository.getFollowers(event.uid);
      emit(FollowersLoaded(followers: followers));
    } catch (e) {
      emit(FollowersError(message: e.toString()));
    }
  }
}
