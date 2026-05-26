// lib/features/profile/presentation/bloc/followers_event.dart
//
// FollowersEvent — events for FollowersBloc.

part of 'followers_bloc.dart';

/// Base class for all followers events.
sealed class FollowersEvent extends Equatable {
  const FollowersEvent();
}

/// Dispatched to load followers for [uid].
final class FollowersLoadRequested extends FollowersEvent {
  /// Creates a [FollowersLoadRequested] event.
  const FollowersLoadRequested({required this.uid});

  /// The UID whose followers to load.
  final String uid;

  @override
  List<Object?> get props => [uid];
}
