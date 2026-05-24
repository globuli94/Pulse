// lib/features/profile/presentation/bloc/profile_bloc.dart
//
// ProfileBloc — manages profile loading, updating, avatar upload, and deletion.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_profile.dart';
import '../../domain/exceptions/profile_exception.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// BLoC that manages user profile state.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  /// Creates a [ProfileBloc].
  ProfileBloc({required ProfileRepository repository})
      : _repository = repository,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AvatarUploadRequested>(_onAvatarUploadRequested);
    on<AccountDeleteRequested>(_onAccountDeleteRequested);
  }

  final ProfileRepository _repository;

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Skip ProfileLoading when freshly starting (ProfileInitial already
    // shows a spinner in the UI); only emit it on re-loads from a loaded state.
    if (state is! ProfileInitial) {
      emit(const ProfileLoading());
    }
    try {
      final profile = await _repository.getProfile(event.uid);
      emit(ProfileLoaded(profile: profile));
    } on ProfileException catch (e) {
      emit(ProfileFailure(message: e.message));
    } catch (e) {
      emit(ProfileFailure(message: 'Failed to load profile.'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentProfile =
        state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
    if (currentProfile != null) {
      emit(ProfileUpdating(profile: currentProfile));
    }
    try {
      final updated = await _repository.updateProfile(
        uid: event.uid,
        displayName: event.displayName,
        bio: event.bio,
      );
      emit(ProfileLoaded(profile: updated));
    } on ProfileException catch (e) {
      emit(ProfileFailure(message: e.message));
    } catch (e) {
      emit(ProfileFailure(message: 'Failed to update profile.'));
    }
  }

  Future<void> _onAvatarUploadRequested(
    AvatarUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final currentProfile =
        state is ProfileLoaded ? (state as ProfileLoaded).profile : null;
    if (currentProfile != null) {
      emit(ProfileUpdating(profile: currentProfile));
    }
    try {
      final updated = await _repository.uploadAvatar(
        uid: event.uid,
        imagePath: event.imagePath,
      );
      emit(ProfileLoaded(profile: updated));
    } on ProfileException catch (e) {
      emit(ProfileFailure(message: e.message));
    } catch (e) {
      emit(ProfileFailure(message: 'Failed to upload avatar.'));
    }
  }

  Future<void> _onAccountDeleteRequested(
    AccountDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _repository.deleteAccount(uid: event.uid);
      emit(const AccountDeleteSuccess());
    } on ProfileException catch (e) {
      emit(ProfileFailure(message: e.message));
    } catch (e) {
      emit(ProfileFailure(message: 'Failed to delete account.'));
    }
  }
}
