// Copyright 2024 Social Media Company. All rights reserved.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/follows/presentation/bloc/follow_bloc.dart';

class MockFollowsRepository extends Mock implements FollowsRepository {}

void main() {
  late MockFollowsRepository mockFollowsRepository;

  setUp(() {
    mockFollowsRepository = MockFollowsRepository();
  });

  group('FollowBloc', () {
    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowLoaded(isFollowing: false)] when FollowStatusCheckRequested succeeds and user is not following',
      build: () {
        when(() => mockFollowsRepository.isFollowing(
              followerId: 'u1',
              followeeId: 'u2',
            )).thenAnswer((_) async => false);
        return FollowBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) => bloc.add(
        const FollowStatusCheckRequested(
          followerId: 'u1',
          followeeId: 'u2',
        ),
      ),
      expect: () => [
        const FollowLoading(),
        const FollowLoaded(isFollowing: false),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowLoaded(isFollowing: true)] when FollowStatusCheckRequested succeeds and user is already following',
      build: () {
        when(() => mockFollowsRepository.isFollowing(
              followerId: 'u1',
              followeeId: 'u2',
            )).thenAnswer((_) async => true);
        return FollowBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) => bloc.add(
        const FollowStatusCheckRequested(
          followerId: 'u1',
          followeeId: 'u2',
        ),
      ),
      expect: () => [
        const FollowLoading(),
        const FollowLoaded(isFollowing: true),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowFailure] when FollowStatusCheckRequested throws',
      build: () {
        when(() => mockFollowsRepository.isFollowing(
              followerId: 'u1',
              followeeId: 'u2',
            )).thenThrow(Exception('Network error'));
        return FollowBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) => bloc.add(
        const FollowStatusCheckRequested(
          followerId: 'u1',
          followeeId: 'u2',
        ),
      ),
      expect: () => [
        const FollowLoading(),
        isA<FollowFailure>(),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowLoaded(isFollowing: true)] when FollowRequested succeeds',
      build: () {
        when(() => mockFollowsRepository.followUser(
              followerId: 'u1',
              followeeId: 'u2',
            )).thenAnswer((_) async => {});
        return FollowBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) => bloc.add(
        const FollowRequested(
          followerId: 'u1',
          followeeId: 'u2',
        ),
      ),
      expect: () => [
        const FollowLoading(),
        const FollowLoaded(isFollowing: true),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowFailure] when FollowRequested throws',
      build: () {
        when(() => mockFollowsRepository.followUser(
              followerId: 'u1',
              followeeId: 'u2',
            )).thenThrow(Exception('Follow failed'));
        return FollowBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) => bloc.add(
        const FollowRequested(
          followerId: 'u1',
          followeeId: 'u2',
        ),
      ),
      expect: () => [
        const FollowLoading(),
        isA<FollowFailure>(),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowLoaded(isFollowing: false)] when UnfollowRequested succeeds',
      build: () {
        when(() => mockFollowsRepository.unfollowUser(
              followerId: 'u1',
              followeeId: 'u2',
            )).thenAnswer((_) async => {});
        return FollowBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) => bloc.add(
        const UnfollowRequested(
          followerId: 'u1',
          followeeId: 'u2',
        ),
      ),
      expect: () => [
        const FollowLoading(),
        const FollowLoaded(isFollowing: false),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowFailure] when UnfollowRequested throws',
      build: () {
        when(() => mockFollowsRepository.unfollowUser(
              followerId: 'u1',
              followeeId: 'u2',
            )).thenThrow(Exception('Unfollow failed'));
        return FollowBloc(followsRepository: mockFollowsRepository);
      },
      act: (bloc) => bloc.add(
        const UnfollowRequested(
          followerId: 'u1',
          followeeId: 'u2',
        ),
      ),
      expect: () => [
        const FollowLoading(),
        isA<FollowFailure>(),
      ],
    );
  });
}
