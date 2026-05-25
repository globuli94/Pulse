import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/posts/domain/entities/post.dart';
import 'package:pulse/features/posts/domain/entities/posts_feed_page.dart';
import 'package:pulse/features/posts/domain/repositories/posts_repository.dart';
import 'package:pulse/features/posts/presentation/bloc/posts_feed_bloc.dart';

class MockPostsRepository extends Mock implements PostsRepository {}

class MockFollowsRepository extends Mock implements FollowsRepository {}

void main() {
  group('PostsFeedBloc', () {
    late MockPostsRepository mockPostsRepository;
    late MockFollowsRepository mockFollowsRepository;
    late PostsFeedBloc postsFeedBloc;

    setUp(() {
      mockPostsRepository = MockPostsRepository();
      mockFollowsRepository = MockFollowsRepository();
      postsFeedBloc = PostsFeedBloc(
        repository: mockPostsRepository,
        followsRepository: mockFollowsRepository,
        currentUserId: 'user1',
      );
    });

    tearDown(() {
      postsFeedBloc.close();
    });

    group('PostsFeedSubscriptionRequested', () {
      test(
          'emits [PostsFeedLoading, PostsFeedLoaded] when stream succeeds with empty list',
          () async {
        when(() => mockPostsRepository.fetchFeed(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => const PostsFeedPage(
              posts: [],
              hasMore: false,
            ));

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

        when(() => mockPostsRepository.fetchFeed(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => PostsFeedPage(
              posts: [testPost],
              hasMore: false,
            ));

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(1));
      });

      test('emits PostsFeedError when stream throws', () async {
        when(() => mockPostsRepository.fetchFeed(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('Fetch error'));

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());

        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedError>());
      });
    });

    group('PostsFeedNextPageRequested', () {
      test('accumulates posts from multiple pages', () async {
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

        // Page 1: one post, more available
        when(() => mockPostsRepository.fetchFeed(
              cursor: null,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => PostsFeedPage(
              posts: [post1],
              hasMore: true,
              cursor: 'cursor-page-2',
            ));

        // Page 2: one post, no more available
        when(() => mockPostsRepository.fetchFeed(
              cursor: 'cursor-page-2',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => PostsFeedPage(
              posts: [post2],
              hasMore: false,
            ));

        // Load first page
        postsFeedBloc.add(const PostsFeedSubscriptionRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(1));
        expect((postsFeedBloc.state as PostsFeedLoaded).hasMore, isTrue);

        // Load next page
        postsFeedBloc.add(const PostsFeedNextPageRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(2));
        expect((postsFeedBloc.state as PostsFeedLoaded).posts[0].id, equals('1'));
        expect((postsFeedBloc.state as PostsFeedLoaded).posts[1].id, equals('2'));
        expect((postsFeedBloc.state as PostsFeedLoaded).hasMore, isFalse);
      });
    });

    group('PostsDeleteRequested', () {
      test('calls repository.deletePost with correct postId and userId', () async {
        when(() => mockPostsRepository.fetchFeed(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
              authorIds: any(named: 'authorIds'),
            )).thenAnswer((_) async => const PostsFeedPage(
              posts: [],
              hasMore: false,
            ));
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

    group('Feed filter by followed users', () {
      test('feeds filters by followed users + own posts', () async {
        final testPost = Post(
          id: '1',
          userId: 'user2',
          displayName: 'User 2',
          text: 'User 2 post',
          createdAt: DateTime(2024, 1, 1),
          imageUrl: null,
        );

        when(() => mockFollowsRepository.getFollowedUserIds(followerId: 'user1'))
            .thenAnswer((_) async => ['user2', 'user3']);

        when(() => mockPostsRepository.fetchFeed(
              cursor: null,
              limit: any(named: 'limit'),
              authorIds: ['user1', 'user2', 'user3'],
            )).thenAnswer((_) async => PostsFeedPage(
              posts: [testPost],
              hasMore: false,
            ));

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockPostsRepository.fetchFeed(
              cursor: null,
              limit: any(named: 'limit'),
              authorIds: ['user1', 'user2', 'user3'],
            )).called(1);

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(1));
      });

      test('feed with no followed users shows only own posts', () async {
        final ownPost = Post(
          id: '1',
          userId: 'user1',
          displayName: 'User 1',
          text: 'Own post',
          createdAt: DateTime(2024, 1, 1),
          imageUrl: null,
        );

        when(() => mockFollowsRepository.getFollowedUserIds(followerId: 'user1'))
            .thenAnswer((_) async => []);

        when(() => mockPostsRepository.fetchFeed(
              cursor: null,
              limit: any(named: 'limit'),
              authorIds: ['user1'],
            )).thenAnswer((_) async => PostsFeedPage(
              posts: [ownPost],
              hasMore: false,
            ));

        postsFeedBloc.add(const PostsFeedSubscriptionRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockPostsRepository.fetchFeed(
              cursor: null,
              limit: any(named: 'limit'),
              authorIds: ['user1'],
            )).called(1);

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
      });

      test('next page uses same authorIds', () async {
        final post1 = Post(
          id: '1',
          userId: 'user2',
          displayName: 'User 2',
          text: 'Post 1',
          createdAt: DateTime(2024, 1, 1),
          imageUrl: null,
        );

        final post2 = Post(
          id: '2',
          userId: 'user3',
          displayName: 'User 3',
          text: 'Post 2',
          createdAt: DateTime(2024, 1, 2),
          imageUrl: null,
        );

        when(() => mockFollowsRepository.getFollowedUserIds(followerId: 'user1'))
            .thenAnswer((_) async => ['user2', 'user3']);

        // Page 1
        when(() => mockPostsRepository.fetchFeed(
              cursor: null,
              limit: any(named: 'limit'),
              authorIds: ['user1', 'user2', 'user3'],
            )).thenAnswer((_) async => PostsFeedPage(
              posts: [post1],
              hasMore: true,
              cursor: 'cursor-page-2',
            ));

        // Page 2 - same authorIds
        when(() => mockPostsRepository.fetchFeed(
              cursor: 'cursor-page-2',
              limit: any(named: 'limit'),
              authorIds: ['user1', 'user2', 'user3'],
            )).thenAnswer((_) async => PostsFeedPage(
              posts: [post2],
              hasMore: false,
            ));

        // Load first page
        postsFeedBloc.add(const PostsFeedSubscriptionRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(postsFeedBloc.state, isA<PostsFeedLoaded>());
        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(1));

        // Load next page
        postsFeedBloc.add(const PostsFeedNextPageRequested());
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify second call also has same authorIds
        verify(() => mockPostsRepository.fetchFeed(
              cursor: 'cursor-page-2',
              limit: any(named: 'limit'),
              authorIds: ['user1', 'user2', 'user3'],
            )).called(1);

        expect((postsFeedBloc.state as PostsFeedLoaded).posts.length, equals(2));
      });
    });
  });
}
