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
    });

    test('initial state is LikeInitial', () {
      final bloc = LikeBloc(repository: mockPostsRepository);
      expect(bloc.state, isA<LikeInitial>());
    });

    blocTest<LikeBloc, LikeState>(
      'LikeInitialised emits [LikeLoading, LikeLoaded(isLiked: false, likeCount: 3)]',
      build: () {
        when(() => mockPostsRepository.isLiked(
              postId: 'p1',
              userId: 'u1',
            )).thenAnswer((_) async => false);
        return LikeBloc(repository: mockPostsRepository);
      },
      act: (bloc) => bloc.add(
        LikeInitialised(postId: 'p1', userId: 'u1', initialLikeCount: 3),
      ),
      expect: () => [
        isA<LikeLoading>(),
        isA<LikeLoaded>()
            .having((state) => state.isLiked, 'isLiked', false)
            .having((state) => state.likeCount, 'likeCount', 3),
      ],
    );

    blocTest<LikeBloc, LikeState>(
      'LikeInitialised emits [LikeLoading, LikeLoaded(isLiked: true, likeCount: 5)]',
      build: () {
        when(() => mockPostsRepository.isLiked(
              postId: 'p1',
              userId: 'u1',
            )).thenAnswer((_) async => true);
        return LikeBloc(repository: mockPostsRepository);
      },
      act: (bloc) => bloc.add(
        LikeInitialised(postId: 'p1', userId: 'u1', initialLikeCount: 5),
      ),
      expect: () => [
        isA<LikeLoading>(),
        isA<LikeLoaded>()
            .having((state) => state.isLiked, 'isLiked', true)
            .having((state) => state.likeCount, 'likeCount', 5),
      ],
    );

    blocTest<LikeBloc, LikeState>(
      'LikeInitialised emits [LikeLoading, LikeError] when isLiked throws',
      build: () {
        when(() => mockPostsRepository.isLiked(
              postId: 'p1',
              userId: 'u1',
            )).thenThrow(Exception('Network error'));
        return LikeBloc(repository: mockPostsRepository);
      },
      act: (bloc) => bloc.add(
        LikeInitialised(postId: 'p1', userId: 'u1', initialLikeCount: 0),
      ),
      expect: () => [
        isA<LikeLoading>(),
        isA<LikeError>()
            .having((state) => state.message, 'message', contains('Network error')),
      ],
    );

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
