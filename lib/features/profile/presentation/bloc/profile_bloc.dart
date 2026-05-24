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
    emit(const ProfileLoading());
    try {
      final profile = await _repository.getProfile(event.uid);
      emit(ProfileLoaded(profile: profile));
    } on ProfileException catch (e) {
      emit(ProfileFailure(error: e.message));
    } catch (e) {
      emit(ProfileFailure(error: 'Failed to load profile.'));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) {
      emit(const ProfileFailure(error: 'Profile not loaded.'));
      return;
    }
    final currentProfile = (state as ProfileLoaded).profile;
    emit(ProfileUpdating(profile: currentProfile));
    try {
      await _repository.updateProfile(
        uid: event.uid,
        displayName: event.displayName,
        bio: event.bio,
      );
      final updated = await _repository.getProfile(event.uid);
      emit(ProfileLoaded(profile: updated));
    } on ProfileException catch (e) {
      emit(ProfileFailure(error: e.message));
    } catch (e) {
      emit(ProfileFailure(error: 'Failed to update profile.'));
    }
  }

  Future<void> _onAvatarUploadRequested(
    AvatarUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) {
      emit(const ProfileFailure(error: 'Profile not loaded.'));
      return;
    }
    final currentProfile = (state as ProfileLoaded).profile;
    emit(ProfileUpdating(profile: currentProfile));
    try {
      await _repository.uploadAvatar(
        uid: event.uid,
        imageBytes: event.imageBytes,
        filename: event.filename,
      );
      final updated = await _repository.getProfile(event.uid);
      emit(ProfileLoaded(profile: updated));
    } on ProfileException catch (e) {
      emit(ProfileFailure(error: e.message));
    } catch (e) {
      emit(ProfileFailure(error: 'Failed to upload avatar.'));
    }
  }

  Future<void> _onAccountDeleteRequested(
    AccountDeleteRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _repository.deleteAccount(event.uid);
      emit(const AccountDeleteSuccess());
    } on ProfileException catch (e) {
      emit(ProfileFailure(error: e.message));
    } catch (e) {
      emit(ProfileFailure(error: 'Failed to delete account.'));
    }
  }
}
