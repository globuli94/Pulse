// lib/features/profile/presentation/bloc/following_state.dart
//
// FollowingState — states for FollowingBloc.

part of 'following_bloc.dart';

/// Base class for all following states.
sealed class FollowingState extends Equatable {
  const FollowingState();
}

/// Initial state before any load.
final class FollowingInitial extends FollowingState {
  /// Creates a [FollowingInitial] state.
  const FollowingInitial();

  @override
  List<Object?> get props => [];
}

/// State while the following list is being fetched.
final class FollowingLoading extends FollowingState {
  /// Creates a [FollowingLoading] state.
  const FollowingLoading();

  @override
  List<Object?> get props => [];
}

/// State when the following list has been successfully loaded.
final class FollowingLoaded extends FollowingState {
  /// Creates a [FollowingLoaded] state.
  const FollowingLoaded({required this.following});

  /// The list of followed user profiles.
  final List<UserProfile> following;

  @override
  List<Object?> get props => [following];
}

/// State when the following list load has failed.
final class FollowingError extends FollowingState {
  /// Creates a [FollowingError] state.
  const FollowingError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
