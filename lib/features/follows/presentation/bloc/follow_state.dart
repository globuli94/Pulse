// lib/features/follows/presentation/bloc/follow_state.dart
//
// FollowState — states for FollowBloc.

part of 'follow_bloc.dart';

/// Base class for all [FollowBloc] states.
sealed class FollowState extends Equatable {
  const FollowState();
}

/// Initial state before any follow status check has been requested.
final class FollowInitial extends FollowState {
  const FollowInitial();

  @override
  List<Object> get props => [];
}

/// A follow/unfollow operation or status check is in progress.
final class FollowLoading extends FollowState {
  const FollowLoading();

  @override
  List<Object> get props => [];
}

/// Follow status is known.
final class FollowLoaded extends FollowState {
  /// Creates a [FollowLoaded].
  const FollowLoaded({required this.isFollowing});

  /// Whether the authenticated user currently follows the viewed profile.
  final bool isFollowing;

  @override
  List<Object> get props => [isFollowing];
}

/// An error occurred during a follow/unfollow operation or status check.
final class FollowFailure extends FollowState {
  /// Creates a [FollowFailure].
  const FollowFailure({required this.error});

  /// Human-readable error message.
  final String error;

  @override
  List<Object> get props => [error];
}
