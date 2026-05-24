import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/domain/repositories/profile_repository.dart';
import 'package:pulse/features/profile/presentation/bloc/user_profile_bloc.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockProfileRepository;
  late UserProfileBloc userProfileBloc;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
    userProfileBloc = UserProfileBloc(profileRepository: mockProfileRepository);
  });

  tearDown(() {
    userProfileBloc.close();
  });

  group('UserProfileBloc', () {
    final testProfile = UserProfile(
      uid: 'other-uid',
      displayName: 'Other User',
      bio: 'Other user bio',
      avatarUrl: 'https://example.com/other-avatar.jpg',
      postCount: 5,
    );

    group('UserProfileLoadRequested', () {
      blocTest<UserProfileBloc, UserProfileState>(
        'emits [UserProfileLoading, UserProfileLoaded] when getProfile succeeds',
        build: () {
          when(() => mockProfileRepository.getProfile('other-uid'))
              .thenAnswer((_) async => testProfile);
          return userProfileBloc;
        },
        act: (bloc) => bloc.add(const UserProfileLoadRequested(uid: 'other-uid')),
        expect: () => [
          UserProfileLoading(),
          UserProfileLoaded(testProfile),
        ],
        verify: (_) {
          verify(() => mockProfileRepository.getProfile('other-uid'))
              .called(1);
        },
      );

      blocTest<UserProfileBloc, UserProfileState>(
        'emits [UserProfileLoading, UserProfileError] when getProfile throws',
        build: () {
          when(() => mockProfileRepository.getProfile(any()))
              .thenThrow(Exception('Load failed'));
          return userProfileBloc;
        },
        act: (bloc) => bloc.add(const UserProfileLoadRequested(uid: 'other-uid')),
        expect: () => [
          UserProfileLoading(),
          isA<UserProfileError>(),
        ],
      );
    });
  });
}
