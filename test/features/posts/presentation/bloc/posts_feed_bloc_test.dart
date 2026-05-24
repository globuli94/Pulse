import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/posts/domain/entities/post.dart';
import 'package:pulse/features/posts/domain/repositories/posts_repository.dart';
import 'package:pulse/features/posts/presentation/bloc/posts_feed_bloc.dart';

class MockPostsRepository extends Mock implements PostsRepository {}

void main() {
  group('PostsFeedBloc', () {
    late MockPostsRepository mockPostsRepository;
    late PostsFeedBloc postsFeedBloc;

    setUp(() {
      mockPostsRepository = MockPostsRepository();
      postsFeedBloc = PostsFeedBloc(repository: mockPostsRepository);
    });

    tearDown(() {
      postsFeedBloc.close();
    });

    group('PostsFeedSubscriptionRequested', () {
      test(
          'emits [PostsFeedLoading, PostsFeedLoaded] when stream succeeds with empty list',
          () async {
        when(() => mockPostsRepository.watchFeed())
            .thenAnswer((_) => Stream.value(const []));

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts, isEmpty);
      });

      test('emits [PostsFeedLoading, PostsFeedLoaded] when stream has posts',
          () async {
        final testPost = Post(
          id: '1',
          userId: 'user1',
          displayName: 'Test User',
          text: 'Test post',
          createdAt: DateTime(2024, 1, 1),
          imageUrl: null,
        );

        when(() => mockPostsRepository.watchFeed())
            .thenAnswer((_) => Stream.value([testPost]));

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(1));
      });

      test('emits PostsFeedError when stream throws', () async {
        when(() => mockPostsRepository.watchFeed())
            .thenAnswer((_) => Stream.error(Exception('Stream error')));

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedError>());
      });
    });

    group('stream updates', () {
      test('emits new PostsFeedLoaded when stream emits new data', () async {
        final post1 = Post(
          id: '1',
          userId: 'user1',
          displayName: 'Test User 1',
          text: 'Test post 1',
          createdAt: DateTime(2024, 1, 1),
          imageUrl: null,
        );

        final post2 = Post(
          id: '2',
          userId: 'user2',
          displayName: 'Test User 2',
          text: 'Test post 2',
          createdAt: DateTime(2024, 1, 2),
          imageUrl: null,
        );

        when(() => mockPostsRepository.watchFeed()).thenAnswer(
          (_) => Stream.fromIterable([[post1], [post1, post2]]),
        );

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());

        await Future.delayed(const Duration(milliseconds: 200));

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(2));
      });
    });

    group('PostsDeleteRequested', () {
      test('calls repository.deletePost with correct postId and userId', () async {
        when(() => mockPostsRepository.watchFeed())
            .thenAnswer((_) => Stream.value(const []));
        when(() => mockPostsRepository.deletePost(
          postId: 'post-123',
          userId: 'user-456',
        )).thenAnswer((_) async {});

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        postsFeedBloc.add(const PostsDeleteRequested(
          postId: 'post-123',
          userId: 'user-456',
        ));
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockPostsRepository.deletePost(
          postId: 'post-123',
          userId: 'user-456',
        )).called(1);
      });
    });
  });
}
