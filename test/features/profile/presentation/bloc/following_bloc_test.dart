// test/features/profile/presentation/bloc/following_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/following_bloc.dart';

class MockFollowsRepository extends Mock implements FollowsRepository {}

void main() {
  late MockFollowsRepository mockFollowsRepository;

  final testFollowing = UserProfile(
    uid: 'following-1',
    displayName: 'Following One',
    bio: '',
    avatarUrl: null,
    postCount: 0,
  );

  setUp(() {
    mockFollowsRepository = MockFollowsRepository();
  });

  group('FollowingBloc', () {
    blocTest<FollowingBloc, FollowingState>(
      'emits [FollowingLoading, FollowingLoaded] when getFollowing succeeds',
      build: () {
        when(() => mockFollowsRepository.getFollowing('uid1'))
            .thenAnswer((_) async => [testFollowing]);
        return FollowingBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) =>
          bloc.add(const FollowingLoadRequested(uid: 'uid1')),
      expect: () => [
        const FollowingLoading(),
        FollowingLoaded(following: [testFollowing]),
      ],
      verify: (_) {
        verify(() => mockFollowsRepository.getFollowing('uid1')).called(1);
      },
    );

    blocTest<FollowingBloc, FollowingState>(
      'emits [FollowingLoading, FollowingError] when getFollowing throws',
      build: () {
        when(() => mockFollowsRepository.getFollowing('uid1'))
            .thenThrow(Exception('network error'));
        return FollowingBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) =>
          bloc.add(const FollowingLoadRequested(uid: 'uid1')),
      expect: () => [
        const FollowingLoading(),
        isA<FollowingError>(),
      ],
    );

    blocTest<FollowingBloc, FollowingState>(
      'emits [FollowingLoading, FollowingLoaded] with empty list',
      build: () {
        when(() => mockFollowsRepository.getFollowing('uid2'))
            .thenAnswer((_) async => []);
        return FollowingBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) =>
          bloc.add(const FollowingLoadRequested(uid: 'uid2')),
      expect: () => [
        const FollowingLoading(),
        const FollowingLoaded(following: []),
      ],
    );
  });
}
