import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/posts/domain/repositories/posts_repository.dart';
import 'package:pulse/features/posts/presentation/bloc/like_bloc.dart';
import 'package:pulse/features/posts/presentation/bloc/like_event.dart';
import 'package:pulse/features/posts/presentation/bloc/like_state.dart';

class MockPostsRepository extends Mock implements PostsRepository {}

void main() {
  group('LikeBloc', () {
    late MockPostsRepository mockPostsRepository;

    setUp(() {
      mockPostsRepository = MockPostsRepository();
      when(() => mockPostsRepository.watchIsLiked(
            postId: any(named: 'postId'), userId: any(named: 'userId')))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockPostsRepository.watchLikeCount(any()))
          .thenAnswer((_) => const Stream.empty());
    });

    test('initial state is LikeInitial', () {
      final bloc = LikeBloc(repository: mockPostsRepository);
      expect(bloc.state, isA<LikeInitial>());
    });

    test('LikeInitialised: emits LikeLoading then LikeLoaded when streams emit', () async {
      final isLikedCtrl = StreamController<bool>.broadcast();
      final countCtrl = StreamController<int>.broadcast();

      when(() => mockPostsRepository.watchIsLiked(postId: 'p1', userId: 'u1'))
          .thenAnswer((_) => isLikedCtrl.stream);
      when(() => mockPostsRepository.watchLikeCount('p1'))
          .thenAnswer((_) => countCtrl.stream);

      final bloc = LikeBloc(repository: mockPostsRepository);
      final states = <LikeState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(LikeInitialised(postId: 'p1', userId: 'u1', initialLikeCount: 3));
      await Future<void>.delayed(Duration.zero);
      expect(states, [isA<LikeLoading>()]);

      isLikedCtrl.add(false);
      await Future<void>.delayed(Duration.zero);
      expect(states.last, isA<LikeLoaded>()
          .having((s) => s.isLiked, 'isLiked', false)
          .having((s) => s.likeCount, 'likeCount', 3));

      countCtrl.add(7);
      await Future<void>.delayed(Duration.zero);
      expect(states.last, isA<LikeLoaded>()
          .having((s) => s.isLiked, 'isLiked', false)
          .having((s) => s.likeCount, 'likeCount', 7));

      await sub.cancel();
      await bloc.close();
      await isLikedCtrl.close();
      await countCtrl.close();
    });

    test('LikeInitialised: external like change on another screen updates state', () async {
      final isLikedCtrl = StreamController<bool>.broadcast();
      final countCtrl = StreamController<int>.broadcast();

      when(() => mockPostsRepository.watchIsLiked(postId: 'p1', userId: 'u1'))
          .thenAnswer((_) => isLikedCtrl.stream);
      when(() => mockPostsRepository.watchLikeCount('p1'))
          .thenAnswer((_) => countCtrl.stream);

      final bloc = LikeBloc(repository: mockPostsRepository);
      bloc.add(LikeInitialised(postId: 'p1', userId: 'u1', initialLikeCount: 2));
      await Future<void>.delayed(Duration.zero);

      isLikedCtrl.add(false);
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as LikeLoaded).isLiked, false);

      // Simulate like from another screen
      isLikedCtrl.add(true);
      countCtrl.add(3);
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as LikeLoaded).isLiked, true);
      expect((bloc.state as LikeLoaded).likeCount, 3);

      await bloc.close();
      await isLikedCtrl.close();
      await countCtrl.close();
    });

    test('LikeInitialised: stream error emits LikeError', () async {
      when(() => mockPostsRepository.watchIsLiked(postId: 'p1', userId: 'u1'))
          .thenAnswer((_) => Stream.error(Exception('Network error')));
      when(() => mockPostsRepository.watchLikeCount('p1'))
          .thenAnswer((_) => const Stream.empty());

      final bloc = LikeBloc(repository: mockPostsRepository);
      final states = <LikeState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(LikeInitialised(postId: 'p1', userId: 'u1', initialLikeCount: 0));
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        isA<LikeLoading>(),
        isA<LikeError>()
            .having((s) => s.message, 'message', contains('Network error')),
      ]);

      await sub.cancel();
      await bloc.close();
    });

    blocTest<LikeBloc, LikeState>(
      'LikeToggleRequested like: emits [LikeLoaded(isLiked: true, likeCount: 4)]',
      build: () {
        when(() => mockPostsRepository.likePost(
              postId: 'p1',
              userId: 'u1',
            )).thenAnswer((_) async => {});
        return LikeBloc(repository: mockPostsRepository);
      },
      seed: () => LikeLoaded(isLiked: false, likeCount: 3),
      act: (bloc) => bloc.add(
        LikeToggleRequested(postId: 'p1', userId: 'u1'),
      ),
      expect: () => [
        isA<LikeLoaded>()
            .having((state) => state.isLiked, 'isLiked', true)
            .having((state) => state.likeCount, 'likeCount', 4),
      ],
    );

    blocTest<LikeBloc, LikeState>(
      'LikeToggleRequested unlike: emits [LikeLoaded(isLiked: false, likeCount: 2)]',
      build: () {
        when(() => mockPostsRepository.unlikePost(
              postId: 'p1',
              userId: 'u1',
            )).thenAnswer((_) async => {});
        return LikeBloc(repository: mockPostsRepository);
      },
      seed: () => LikeLoaded(isLiked: true, likeCount: 3),
      act: (bloc) => bloc.add(
        LikeToggleRequested(postId: 'p1', userId: 'u1'),
      ),
      expect: () => [
        isA<LikeLoaded>()
            .having((state) => state.isLiked, 'isLiked', false)
            .having((state) => state.likeCount, 'likeCount', 2),
      ],
    );

    blocTest<LikeBloc, LikeState>(
      'LikeToggleRequested rollback on error: emits [LikeLoaded(isLiked: true, likeCount: 2), LikeLoaded(isLiked: false, likeCount: 1)]',
      build: () {
        when(() => mockPostsRepository.likePost(
              postId: 'p1',
              userId: 'u1',
            )).thenThrow(Exception('Firestore error'));
        return LikeBloc(repository: mockPostsRepository);
      },
      seed: () => LikeLoaded(isLiked: false, likeCount: 1),
      act: (bloc) => bloc.add(
        LikeToggleRequested(postId: 'p1', userId: 'u1'),
      ),
      expect: () => [
        isA<LikeLoaded>()
            .having((state) => state.isLiked, 'isLiked', true)
            .having((state) => state.likeCount, 'likeCount', 2),
        isA<LikeLoaded>()
            .having((state) => state.isLiked, 'isLiked', false)
            .having((state) => state.likeCount, 'likeCount', 1),
      ],
    );

    blocTest<LikeBloc, LikeState>(
      'LikeToggleRequested when state is NOT LikeLoaded emits nothing',
      build: () => LikeBloc(repository: mockPostsRepository),
      seed: () => LikeLoading(),
      act: (bloc) => bloc.add(
        LikeToggleRequested(postId: 'p1', userId: 'u1'),
      ),
      expect: () => [],
    );
  });
}
