// lib/features/profile/presentation/bloc/user_profile_bloc.dart
//
// UserProfileBloc — screen-scoped BLoC for viewing another user's profile.
//
// Do NOT register this in main.dart — it is provided per-route.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

/// BLoC for loading a read-only view of any user's profile.
///
/// Screen-scoped: provided in the `/profile/:uid` route builder, not globally.
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  /// Creates a [UserProfileBloc].
  UserProfileBloc({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const UserProfileInitial()) {
    on<UserProfileLoadRequested>(_onUserProfileLoadRequested);
  }

  final ProfileRepository _profileRepository;

  Future<void> _onUserProfileLoadRequested(
    UserProfileLoadRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(const UserProfileLoading());
    try {
      final profile = await _profileRepository.getProfile(event.uid);
      emit(UserProfileLoaded(profile));
    } catch (e) {
      emit(UserProfileError(e.toString()));
    }
  }
}
