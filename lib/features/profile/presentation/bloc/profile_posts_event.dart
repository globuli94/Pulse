// lib/features/profile/presentation/bloc/profile_posts_event.dart
//
// ProfilePostsEvent — events for ProfilePostsBloc.

part of 'profile_posts_bloc.dart';

/// Base class for all profile-posts events.
sealed class ProfilePostsEvent extends Equatable {
  const ProfilePostsEvent();
}

/// Dispatched to load posts for the user with [uid].
final class ProfilePostsLoadRequested extends ProfilePostsEvent {
  /// Creates a [ProfilePostsLoadRequested] event.
  const ProfilePostsLoadRequested({required this.uid});

  /// The UID of the user whose posts to load.
  final String uid;

  @override
  List<Object?> get props => [uid];
}
