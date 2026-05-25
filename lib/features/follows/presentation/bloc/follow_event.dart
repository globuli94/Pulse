// lib/features/follows/presentation/bloc/follow_event.dart
//
// FollowEvent — events for FollowBloc.

part of 'follow_bloc.dart';

/// Base class for all [FollowBloc] events.
sealed class FollowEvent extends Equatable {
  const FollowEvent();
}

/// Checks the current follow status for the given user pair.
final class FollowStatusCheckRequested extends FollowEvent {
  /// Creates a [FollowStatusCheckRequested].
  const FollowStatusCheckRequested({
    required this.followerId,
    required this.followeeId,
  });

  /// The authenticated user's UID.
  final String followerId;

  /// The UID of the profile being viewed.
  final String followeeId;

  @override
  List<Object> get props => [followerId, followeeId];
}

/// The authenticated user wants to follow [followeeId].
final class FollowRequested extends FollowEvent {
  /// Creates a [FollowRequested].
  const FollowRequested({
    required this.followerId,
    required this.followeeId,
  });

  /// The authenticated user's UID.
  final String followerId;

  /// The UID of the user to follow.
  final String followeeId;

  @override
  List<Object> get props => [followerId, followeeId];
}

/// The authenticated user wants to unfollow [followeeId].
final class UnfollowRequested extends FollowEvent {
  /// Creates an [UnfollowRequested].
  const UnfollowRequested({
    required this.followerId,
    required this.followeeId,
  });

  /// The authenticated user's UID.
  final String followerId;

  /// The UID of the user to unfollow.
  final String followeeId;

  @override
  List<Object> get props => [followerId, followeeId];
}
