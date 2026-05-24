import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/domain/exceptions/profile_exception.dart';
import 'package:pulse/features/profile/domain/repositories/profile_repository.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfileBloc', () {
    late MockProfileRepository mockProfileRepository;
    late ProfileBloc profileBloc;

    setUp(() {
      mockProfileRepository = MockProfileRepository();
      profileBloc = ProfileBloc(repository: mockProfileRepository);
    });

    tearDown(() {
      profileBloc.close();
    });

    test('initial state is ProfileInitial', () {
      expect(profileBloc.state, isA<ProfileInitial>());
    });

    group('ProfileLoadRequested', () {
      test(
        'emits [ProfileLoading, ProfileLoaded] when getProfile succeeds',
        () async {
          final userProfile = UserProfile(
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

          when(() => mockProfileRepository.getProfile('test-uid')).thenAnswer(
            (_) async => userProfile,
          );

          profileBloc.add(const ProfileLoadRequested());

          await expectLater(
            profileBloc.stream,
            emitsInOrder([
              isA<ProfileLoading>(),
              isA<ProfileLoaded>().having(
                (state) => state.profile.uid,
                'uid',
                'test-uid',
              ),
            ]),
          );
        },
      );

      test(
        'emits [ProfileLoading, ProfileFailure] when repository throws',
        () async {
          when(() => mockProfileRepository.getProfile('test-uid')).thenThrow(
            ProfileException('User not found.'),
          );

          profileBloc.add(const ProfileLoadRequested());

          await expectLater(
            profileBloc.stream,
            emitsInOrder([
              isA<ProfileLoading>(),
              isA<ProfileFailure>().having(
                (state) => state.message,
                'message',
                'User not found.',
              ),
            ]),
          );
        },
      );

      test(
        'emits ProfileFailure when document does not exist',
        () async {
          when(() => mockProfileRepository.getProfile('nonexistent')).thenThrow(
            ProfileException('User not found.'),
          );

          profileBloc.add(const ProfileLoadRequested(uid: 'nonexistent'));

          await expectLater(
            profileBloc.stream,
            emits(
              isA<ProfileFailure>().having(
                (state) => state.message,
                'message',
                'User not found.',
              ),
            ),
          );
        },
      );
    });

    group('ProfileUpdateRequested', () {
      test(
        'emits [ProfileUpdating, ProfileLoaded] when updateProfile succeeds',
        () async {
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

          when(
            () => mockProfileRepository.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).thenAnswer((_) async => updatedProfile);

          profileBloc.add(
            const ProfileUpdateRequested(
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          );

          await expectLater(
            profileBloc.stream,
            emitsInOrder([
              isA<ProfileUpdating>(),
              isA<ProfileLoaded>().having(
                (state) => state.profile.displayName,
                'displayName',
                'Updated Name',
              ),
            ]),
          );
        },
      );

      test(
        'emits [ProfileUpdating, ProfileFailure] when updateProfile fails',
        () async {
          when(
            () => mockProfileRepository.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).thenThrow(ProfileException('Network error'));

          profileBloc.add(
            const ProfileUpdateRequested(
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          );

          await expectLater(
            profileBloc.stream,
            emitsInOrder([
              isA<ProfileUpdating>(),
              isA<ProfileFailure>().having(
                (state) => state.message,
                'message',
                'Network error',
              ),
            ]),
          );
        },
      );

      test(
        'does not send postCount or other fields to repository',
        () async {
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

          when(
            () => mockProfileRepository.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).thenAnswer((_) async => updatedProfile);

          profileBloc.add(
            const ProfileUpdateRequested(
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          );

          await expectLater(
            profileBloc.stream,
            emits(isA<ProfileLoaded>()),
          );

          verify(
            () => mockProfileRepository.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
            ),
          ).called(1);
        },
      );
    });

    group('AvatarUploadRequested', () {
      test(
        'emits [ProfileUpdating, ProfileLoaded] with new avatarUrl',
        () async {
          final updatedProfile = UserProfile(
            uid: 'test-uid',
            displayName: 'Test User',
            username: 'testuser',
            bio: 'Test bio',
            avatarUrl: 'https://example.com/new-avatar.jpg',
            followerCount: 10,
            followingCount: 5,
            postCount: 3,
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 2),
          );

          when(
            () => mockProfileRepository.uploadAvatar(
              uid: 'test-uid',
              imagePath: '/path/to/image.jpg',
            ),
          ).thenAnswer((_) async => updatedProfile);

          profileBloc.add(
            const AvatarUploadRequested(imagePath: '/path/to/image.jpg'),
          );

          await expectLater(
            profileBloc.stream,
            emitsInOrder([
              isA<ProfileUpdating>(),
              isA<ProfileLoaded>().having(
                (state) => state.profile.avatarUrl,
                'avatarUrl',
                'https://example.com/new-avatar.jpg',
              ),
            ]),
          );
        },
      );

      test(
        'emits [ProfileUpdating, ProfileFailure] when upload fails',
        () async {
          when(
            () => mockProfileRepository.uploadAvatar(
              uid: 'test-uid',
              imagePath: '/path/to/image.jpg',
            ),
          ).thenThrow(ProfileException('Upload failed'));

          profileBloc.add(
            const AvatarUploadRequested(imagePath: '/path/to/image.jpg'),
          );

          await expectLater(
            profileBloc.stream,
            emitsInOrder([
              isA<ProfileUpdating>(),
              isA<ProfileFailure>().having(
                (state) => state.message,
                'message',
                'Upload failed',
              ),
            ]),
          );
        },
      );
    });

    group('AccountDeleteRequested', () {
      test(
        'emits AccountDeleteSuccess when deleteAccount succeeds',
        () async {
          when(
            () => mockProfileRepository.deleteAccount(uid: 'test-uid'),
          ).thenAnswer((_) async => {});

          profileBloc.add(const AccountDeleteRequested());

          await expectLater(
            profileBloc.stream,
            emits(isA<AccountDeleteSuccess>()),
          );
        },
      );

      test(
        'emits ProfileFailure when deleteAccount fails',
        () async {
          when(
            () => mockProfileRepository.deleteAccount(uid: 'test-uid'),
          ).thenThrow(ProfileException('Delete failed'));

          profileBloc.add(const AccountDeleteRequested());

          await expectLater(
            profileBloc.stream,
            emits(
              isA<ProfileFailure>().having(
                (state) => state.message,
                'message',
                'Delete failed',
              ),
            ),
          );
        },
      );
    });
  });
}
