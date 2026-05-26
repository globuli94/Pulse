// lib/features/profile/presentation/bloc/profile_posts_state.dart
//
// ProfilePostsState — states for ProfilePostsBloc.

part of 'profile_posts_bloc.dart';

/// Base class for all profile-posts states.
sealed class ProfilePostsState extends Equatable {
  const ProfilePostsState();
}

/// Initial state before any load has been requested.
final class ProfilePostsInitial extends ProfilePostsState {
  /// Creates a [ProfilePostsInitial] state.
  const ProfilePostsInitial();

  @override
  List<Object?> get props => [];
}

/// State while posts are being fetched.
final class ProfilePostsLoading extends ProfilePostsState {
  /// Creates a [ProfilePostsLoading] state.
  const ProfilePostsLoading();

  @override
  List<Object?> get props => [];
}

/// State when posts have been successfully loaded.
final class ProfilePostsLoaded extends ProfilePostsState {
  /// Creates a [ProfilePostsLoaded] state.
  const ProfilePostsLoaded({required this.posts});

  /// The loaded list of posts.
  final List<Post> posts;

  @override
  List<Object?> get props => [posts];
}

/// State when the posts load has failed.
final class ProfilePostsError extends ProfilePostsState {
  /// Creates a [ProfilePostsError] state.
  const ProfilePostsError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
