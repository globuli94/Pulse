// lib/features/profile/presentation/bloc/followers_state.dart
//
// FollowersState — states for FollowersBloc.

part of 'followers_bloc.dart';

/// Base class for all followers states.
sealed class FollowersState extends Equatable {
  const FollowersState();
}

/// Initial state before any load.
final class FollowersInitial extends FollowersState {
  /// Creates a [FollowersInitial] state.
  const FollowersInitial();

  @override
  List<Object?> get props => [];
}

/// State while followers are being fetched.
final class FollowersLoading extends FollowersState {
  /// Creates a [FollowersLoading] state.
  const FollowersLoading();

  @override
  List<Object?> get props => [];
}

/// State when followers have been successfully loaded.
final class FollowersLoaded extends FollowersState {
  /// Creates a [FollowersLoaded] state.
  const FollowersLoaded({required this.followers});

  /// The list of follower profiles.
  final List<UserProfile> followers;

  @override
  List<Object?> get props => [followers];
}

/// State when the followers load has failed.
final class FollowersError extends FollowersState {
  /// Creates a [FollowersError] state.
  const FollowersError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
