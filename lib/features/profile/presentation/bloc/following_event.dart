// lib/features/profile/presentation/bloc/following_event.dart
//
// FollowingEvent — events for FollowingBloc.

part of 'following_bloc.dart';

/// Base class for all following events.
sealed class FollowingEvent extends Equatable {
  const FollowingEvent();
}

/// Dispatched to load the list of users that [uid] follows.
final class FollowingLoadRequested extends FollowingEvent {
  /// Creates a [FollowingLoadRequested] event.
  const FollowingLoadRequested({required this.uid});

  /// The UID whose following list to load.
  final String uid;

  @override
  List<Object?> get props => [uid];
}
