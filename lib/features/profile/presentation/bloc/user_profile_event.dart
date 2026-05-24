// lib/features/profile/presentation/bloc/user_profile_event.dart
//
// UserProfileEvent — events for the screen-scoped UserProfileBloc.

part of 'user_profile_bloc.dart';

/// Base class for all user-profile-view events.
sealed class UserProfileEvent extends Equatable {
  const UserProfileEvent();
}

/// Dispatched to load the profile for the given [uid].
final class UserProfileLoadRequested extends UserProfileEvent {
  /// Creates a [UserProfileLoadRequested] event.
  const UserProfileLoadRequested({required this.uid});

  /// The UID of the user whose profile to load.
  final String uid;

  @override
  List<Object?> get props => [uid];
}
