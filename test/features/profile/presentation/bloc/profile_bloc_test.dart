import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/domain/repositories/profile_repository.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late MockAuthRepository mockAuthRepository;
  late ProfileBloc profileBloc;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    mockAuthRepository = MockAuthRepository();
    profileBloc = ProfileBloc(
      profileRepository: mockProfileRepository,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    profileBloc.close();
  });

  group('ProfileBloc', () {
    final testProfile = UserProfile(
      uid: 'test-uid',
      displayName: 'Test User',
      bio: 'Test bio',
      avatarUrl: 'https://example.com/avatar.jpg',
      postCount: 3,
    );

    group('ProfileLoadRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when getProfile succeeds',
        build: () {
          when(() => mockProfileRepository.getProfile('test-uid'))
              .thenAnswer((_) async => testProfile);
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested(uid: 'test-uid')),
        expect: () => [
          ProfileLoading(),
          ProfileLoaded(profile: testProfile),
        ],
        verify: (_) {
          verify(() => mockProfileRepository.getProfile('test-uid')).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when getProfile throws',
        build: () {
          when(() => mockProfileRepository.getProfile(any()))
              .thenThrow(Exception('Load failed'));
          return profileBloc;
        },
        act: (bloc) => bloc.add(const ProfileLoadRequested(uid: 'test-uid')),
        expect: () => [
          ProfileLoading(),
          isA<ProfileError>(),
        ],
      );
    });

    group('ProfileUpdateRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileUpdateSuccess] without avatar',
        build: () {
          final updatedProfile = UserProfile(
            uid: testProfile.uid,
            displayName: 'Updated Name',
            bio: 'Updated bio',
            avatarUrl: testProfile.avatarUrl,
            postCount: testProfile.postCount,
          );
          when(() => mockProfileRepository.updateProfile(
                uid: 'test-uid',
                displayName: 'Updated Name',
                bio: 'Updated bio',
              )).thenAnswer((_) async {});
          when(() => mockProfileRepository.getProfile('test-uid'))
              .thenAnswer((_) async => updatedProfile);
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileUpdateRequested(
          uid: 'test-uid',
          displayName: 'Updated Name',
          bio: 'Updated bio',
        )),
        expect: () => [
          ProfileUpdating(profile: testProfile),
          isA<ProfileUpdateSuccess>(),
        ],
        verify: (_) {
          verify(() => mockProfileRepository.updateProfile(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          )).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'calls uploadAvatar first when avatar path provided',
        build: () {
          final updatedProfile = UserProfile(
            uid: testProfile.uid,
            displayName: 'Updated Name',
            bio: 'Updated bio',
            avatarUrl: 'https://example.com/new-avatar.jpg',
            postCount: testProfile.postCount,
          );
          when(() => mockProfileRepository.uploadAvatar(
                uid: 'test-uid',
                localFilePath: '/path/to/avatar.jpg',
              )).thenAnswer((_) async => 'https://example.com/new-avatar.jpg');
          when(() => mockProfileRepository.updateProfile(
                uid: 'test-uid',
                displayName: 'Updated Name',
                bio: 'Updated bio',
                avatarUrl: 'https://example.com/new-avatar.jpg',
              )).thenAnswer((_) async {});
          when(() => mockProfileRepository.getProfile('test-uid'))
              .thenAnswer((_) async => updatedProfile);
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileUpdateRequested(
          uid: 'test-uid',
          displayName: 'Updated Name',
          bio: 'Updated bio',
          avatarFilePath: '/path/to/avatar.jpg',
        )),
        expect: () => [
          ProfileUpdating(profile: testProfile),
          isA<ProfileUpdateSuccess>(),
        ],
        verify: (_) {
          verifyInOrder([
            () => mockProfileRepository.uploadAvatar(
              uid: 'test-uid',
              localFilePath: '/path/to/avatar.jpg',
            ),
            () => mockProfileRepository.updateProfile(
              uid: 'test-uid',
              displayName: 'Updated Name',
              bio: 'Updated bio',
              avatarUrl: 'https://example.com/new-avatar.jpg',
            ),
          ]);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdating, ProfileError] when update fails',
        build: () {
          when(() => mockProfileRepository.updateProfile(
            uid: any(named: 'uid'),
            displayName: any(named: 'displayName'),
            bio: any(named: 'bio'),
          )).thenThrow(Exception('Update failed'));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileUpdateRequested(
          uid: 'test-uid',
          displayName: 'Updated Name',
          bio: 'Updated bio',
        )),
        expect: () => [
          ProfileUpdating(profile: testProfile),
          isA<ProfileError>(),
        ],
      );
    });

    group('ProfileSignOutRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileSignedOut] when signOut succeeds',
        build: () {
          when(() => mockAuthRepository.signOut()).thenAnswer((_) async => {});
          return profileBloc;
        },
        act: (bloc) => bloc.add(ProfileSignOutRequested()),
        expect: () => [
          ProfileSignedOut(),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.signOut()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileError] when signOut throws',
        build: () {
          when(() => mockAuthRepository.signOut())
              .thenThrow(Exception('Sign out failed'));
          return profileBloc;
        },
        act: (bloc) => bloc.add(ProfileSignOutRequested()),
        expect: () => [
          isA<ProfileError>(),
        ],
      );
    });

    group('ProfileDeleteAccountRequested', () {
      blocTest<ProfileBloc, ProfileState>(
        'BUG-001d: emits [ProfileAccountDeleted] when deleteAccount succeeds and calls signOut',
        build: () {
          when(() => mockProfileRepository.deleteAccount())
              .thenAnswer((_) async => {});
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async => {});
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileDeleteAccountRequested()),
        expect: () => [
          const ProfileAccountDeleted(),
        ],
        verify: (_) {
          verify(() => mockProfileRepository.deleteAccount()).called(1);
          verify(() => mockAuthRepository.signOut()).called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileAccountDeleted] when deleteAccount succeeds',
        build: () {
          when(() => mockProfileRepository.deleteAccount())
              .thenAnswer((_) async => {});
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileDeleteAccountRequested()),
        expect: () => [
          const ProfileAccountDeleted(),
        ],
        verify: (_) {
          verify(() => mockProfileRepository.deleteAccount())
              .called(1);
        },
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileError] when deleteAccount throws',
        build: () {
          when(() => mockProfileRepository.deleteAccount())
              .thenThrow(Exception('Delete failed'));
          return profileBloc;
        },
        seed: () => ProfileLoaded(profile: testProfile),
        act: (bloc) => bloc.add(const ProfileDeleteAccountRequested()),
        expect: () => [
          isA<ProfileError>(),
        ],
      );
    });
  });
}
