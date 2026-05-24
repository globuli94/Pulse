// lib/features/profile/presentation/bloc/profile_bloc.dart
//
// ProfileBloc — manages global user profile state.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// BLoC responsible for managing the authenticated user's profile state.
///
/// Registered globally in `main.dart` as a [BlocProvider].
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  /// Creates a [ProfileBloc].
  ProfileBloc({
    required ProfileRepository profileRepository,
    required AuthRepository authRepository,
  })  : _profileRepository = profileRepository,
        _authRepository = authRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileSignOutRequested>(_onProfileSignOutRequested);
    on<ProfileDeleteAccountRequested>(_onProfileDeleteAccountRequested);
  }

  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final profile = await _profileRepository.getProfile(event.uid);
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentProfile = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : state is ProfileUpdateSuccess
            ? (state as ProfileUpdateSuccess).profile
            : null;

    if (currentProfile != null) {
      emit(ProfileUpdating(profile: currentProfile));
    }

    try {
      String? avatarUrl;
      if (event.avatarFilePath != null) {
        avatarUrl = await _profileRepository.uploadAvatar(
          uid: event.uid,
          localFilePath: event.avatarFilePath!,
        );
      }

      await _profileRepository.updateProfile(
        uid: event.uid,
        displayName: event.displayName,
        bio: event.bio,
        avatarUrl: avatarUrl,
      );

      final updatedProfile = await _profileRepository.getProfile(event.uid);
      emit(ProfileUpdateSuccess(profile: updatedProfile));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onProfileSignOutRequested(
    ProfileSignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      emit(const ProfileSignedOut());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onProfileDeleteAccountRequested(
    ProfileDeleteAccountRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _profileRepository.deleteAccount();
      emit(const ProfileAccountDeleted());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
