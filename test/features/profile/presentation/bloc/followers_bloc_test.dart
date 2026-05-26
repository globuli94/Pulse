// test/features/profile/presentation/bloc/followers_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/followers_bloc.dart';

class MockFollowsRepository extends Mock implements FollowsRepository {}

void main() {
  late MockFollowsRepository mockFollowsRepository;

  final testFollower = UserProfile(
    uid: 'follower-1',
    displayName: 'Follower One',
    bio: '',
    avatarUrl: null,
    postCount: 0,
  );

  setUp(() {
    mockFollowsRepository = MockFollowsRepository();
  });

  group('FollowersBloc', () {
    blocTest<FollowersBloc, FollowersState>(
      'emits [FollowersLoading, FollowersLoaded] when getFollowers succeeds',
      build: () {
        when(() => mockFollowsRepository.getFollowers('uid1'))
            .thenAnswer((_) async => [testFollower]);
        return FollowersBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) =>
          bloc.add(const FollowersLoadRequested(uid: 'uid1')),
      expect: () => [
        const FollowersLoading(),
        FollowersLoaded(followers: [testFollower]),
      ],
      verify: (_) {
        verify(() => mockFollowsRepository.getFollowers('uid1')).called(1);
      },
    );

    blocTest<FollowersBloc, FollowersState>(
      'emits [FollowersLoading, FollowersError] when getFollowers throws',
      build: () {
        when(() => mockFollowsRepository.getFollowers('uid1'))
            .thenThrow(Exception('network error'));
        return FollowersBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) =>
          bloc.add(const FollowersLoadRequested(uid: 'uid1')),
      expect: () => [
        const FollowersLoading(),
        isA<FollowersError>(),
      ],
    );

    blocTest<FollowersBloc, FollowersState>(
      'emits [FollowersLoading, FollowersLoaded] with empty list',
      build: () {
        when(() => mockFollowsRepository.getFollowers('uid2'))
            .thenAnswer((_) async => []);
        return FollowersBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) =>
          bloc.add(const FollowersLoadRequested(uid: 'uid2')),
      expect: () => [
        const FollowersLoading(),
        const FollowersLoaded(followers: []),
      ],
    );
  });
}
