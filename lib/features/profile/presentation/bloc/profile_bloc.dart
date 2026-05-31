// lib/features/profile/presentation/bloc/profile_bloc.dart
//
// ProfileBloc — manages global user profile state.

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../posts/domain/repositories/posts_repository.dart';
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
    required PostsRepository postsRepository,
  })  : _profileRepository = profileRepository,
        _authRepository = authRepository,
        _postsRepository = postsRepository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfileSignOutRequested>(_onProfileSignOutRequested);
    on<ProfileDeleteAccountRequested>(_onProfileDeleteAccountRequested);
  }

  final ProfileRepository _profileRepository;
  final AuthRepository _authRepository;
  final PostsRepository _postsRepository;

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

      // Best-effort: propagate the new name/avatar to existing posts.
      // A failure here must not surface as a profile-save failure.
      try {
        await _postsRepository.updateAuthorInfoOnPosts(
          userId: event.uid,
          displayName: updatedProfile.displayName,
          avatarUrl: updatedProfile.avatarUrl,
        );
      } catch (e) {
        debugPrint('ProfileBloc: updateAuthorInfoOnPosts failed: $e');
      }
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
      await _authRepository.signOut();
      emit(const ProfileAccountDeleted());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
