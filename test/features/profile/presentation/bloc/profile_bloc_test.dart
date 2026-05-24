// test/features/profile/presentation/bloc/profile_bloc_test.dart
//
// Unit tests for ProfileBloc — covers all event handlers and state transitions.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/domain/exceptions/profile_exception.dart';
import 'package:pulse/features/profile/domain/repositories/profile_repository.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfileBloc', () {
    late MockProfileRepository mockRepo;

    final baseProfile = UserProfile(
      uid: 'test-uid',
      displayName: 'Test User',
      username: 'testuser',
      bio: 'Test bio',
      avatarUrl: 'https://example.com/avatar.jpg',
      followerCount: 10,
      followingCount: 5,
      postCount: 3,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    setUp(() {
      mockRepo = MockProfileRepository();
    });

    test('initial state is ProfileInitial', () {
      final bloc = ProfileBloc(repository: mockRepo);
      expect(bloc.state, isA<ProfileInitial>());
      bloc.close();
    });

    group('ProfileLoadRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoaded] when getProfile succeeds from initial state',
        build: () => ProfileBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.getProfile('test-uid'))
              .thenAnswer((_) async => baseProfile);
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested(uid: 'test-uid')),
        expect: () => [
          isA<ProfileLoaded>().having(
            (s) => s.profile.uid,
            'uid',
            'test-uid',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileFailure] when repository throws from initial state',
        build: () => ProfileBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.getProfile('test-uid'))
              .thenThrow(const ProfileException('User not found.'));
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested(uid: 'test-uid')),
        expect: () => [
          isA<ProfileFailure>().having(
            (s) => s.message,
            'message',
            'User not found.',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileFailure when document does not exist',
        build: () => ProfileBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.getProfile('nonexistent'))
              .thenThrow(const ProfileException('User not found.'));
        },
        act: (bloc) =>
            bloc.add(const ProfileLoadRequested(uid: 'nonexistent')),
        expect: () => [
          isA<ProfileFailure>().having(
            (s) => s.message,
            'message',
            'User not found.',
          ),
        ],
      );
    });

    group('ProfileUpdateRequested', () {
      final updatedProfile = UserProfile(
        uid: 'test-uid',
        displayName: 'Updated Name',
        username: 'testuser',
        bio: 'Updated bio',
        avatarUrl: '',
        followerCount: 10,
        followingCount: 5,
        postCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 3),
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileLoaded] when updateProfile succeeds',
        build: () => ProfileBloc(repository: mockRepo),
        seed: () => ProfileLoaded(profile: baseProfile),
        setUp: () {
          when(
            () => mockRepo.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).thenAnswer((_) async => updatedProfile);
        },
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          ),
        ),
        expect: () => [
          isA<ProfileUpdating>(),
          isA<ProfileLoaded>().having(
            (s) => s.profile.displayName,
            'displayName',
            'Updated Name',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileFailure] when updateProfile fails',
        build: () => ProfileBloc(repository: mockRepo),
        seed: () => ProfileLoaded(profile: baseProfile),
        setUp: () {
          when(
            () => mockRepo.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).thenThrow(const ProfileException('Network error'));
        },
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          ),
        ),
        expect: () => [
          isA<ProfileUpdating>(),
          isA<ProfileFailure>().having(
            (s) => s.message,
            'message',
            'Network error',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'does not send postCount or other fields to repository',
        build: () => ProfileBloc(repository: mockRepo),
        seed: () => ProfileLoaded(profile: baseProfile),
        setUp: () {
          when(
            () => mockRepo.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).thenAnswer((_) async => updatedProfile);
        },
        act: (bloc) => bloc.add(
          const ProfileUpdateRequested(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          ),
        ),
        verify: (_) {
          verify(
            () => mockRepo.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).called(1);
        },
      );
    });

    group('AvatarUploadRequested', () {
      final profileWithNewAvatar = baseProfile.copyWith(
        avatarUrl: 'https://example.com/new-avatar.jpg',
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileLoaded] with new avatarUrl',
        build: () => ProfileBloc(repository: mockRepo),
        seed: () => ProfileLoaded(profile: baseProfile),
        setUp: () {
          when(
            () => mockRepo.uploadAvatar(
              uid: 'test-uid',
              imagePath: '/path/to/image.jpg',
            ),
          ).thenAnswer((_) async => profileWithNewAvatar);
        },
        act: (bloc) => bloc.add(
          const AvatarUploadRequested(
            uid: 'test-uid',
            imagePath: '/path/to/image.jpg',
          ),
        ),
        expect: () => [
          isA<ProfileUpdating>(),
          isA<ProfileLoaded>().having(
            (s) => s.profile.avatarUrl,
            'avatarUrl',
            'https://example.com/new-avatar.jpg',
          ),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileFailure] when upload fails',
        build: () => ProfileBloc(repository: mockRepo),
        seed: () => ProfileLoaded(profile: baseProfile),
        setUp: () {
          when(
            () => mockRepo.uploadAvatar(
              uid: 'test-uid',
              imagePath: '/path/to/image.jpg',
            ),
          ).thenThrow(const ProfileException('Upload failed'));
        },
        act: (bloc) => bloc.add(
          const AvatarUploadRequested(
            uid: 'test-uid',
            imagePath: '/path/to/image.jpg',
          ),
        ),
        expect: () => [
          isA<ProfileUpdating>(),
          isA<ProfileFailure>().having(
            (s) => s.message,
            'message',
            'Upload failed',
          ),
        ],
      );
    });

    group('AccountDeleteRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits AccountDeleteSuccess when deleteAccount succeeds',
        build: () => ProfileBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.deleteAccount(uid: 'test-uid'))
              .thenAnswer((_) async {});
        },
        act: (bloc) =>
            bloc.add(const AccountDeleteRequested(uid: 'test-uid')),
        expect: () => [isA<AccountDeleteSuccess>()],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileFailure when deleteAccount fails',
        build: () => ProfileBloc(repository: mockRepo),
        setUp: () {
          when(() => mockRepo.deleteAccount(uid: 'test-uid'))
              .thenThrow(const ProfileException('Delete failed'));
        },
        act: (bloc) =>
            bloc.add(const AccountDeleteRequested(uid: 'test-uid')),
        expect: () => [
          isA<ProfileFailure>().having(
            (s) => s.message,
            'message',
            'Delete failed',
          ),
        ],
      );
    });
  });
}
