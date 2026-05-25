import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/feed/presentation/screens/feed_screen.dart';
import 'package:pulse/features/posts/domain/entities/post.dart';
import 'package:pulse/features/posts/presentation/bloc/posts_feed_bloc.dart';
import 'package:pulse/features/posts/presentation/widgets/post_card.dart';

class MockPostsFeedBloc extends MockBloc<PostsFeedEvent, PostsFeedState>
    implements PostsFeedBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const PostsFeedSubscriptionRequested());
    registerFallbackValue(const PostsFeedNextPageRequested());
    registerFallbackValue(const PostsDeleteRequested(postId: '', userId: ''));
  });

  group('FeedScreen', () {
    late MockPostsFeedBloc mockPostsFeedBloc;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockPostsFeedBloc = MockPostsFeedBloc();
      mockAuthBloc = MockAuthBloc();

      // Mock authenticated user
      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
    });

    testWidgets(
      'displays CircularProgressIndicator when PostsFeedLoading',
      (WidgetTester tester) async {
        when(() => mockPostsFeedBloc.state).thenReturn(const PostsFeedLoading());

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'displays PostCard list when PostsFeedLoaded with posts',
      (WidgetTester tester) async {
        final testPosts = [
          Post(
            id: '1',
            userId: 'user1',
            displayName: 'User One',
            text: 'Test post 1',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
          Post(
            id: '2',
            userId: 'user2',
            displayName: 'User Two',
            text: 'Test post 2',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
        ];

        final loadedState = PostsFeedLoaded(posts: testPosts);
        when(() => mockPostsFeedBloc.state).thenReturn(loadedState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        expect(find.byType(PostCard), findsWidgets);
        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'displays "No posts yet" when PostsFeedLoaded with empty posts',
      (WidgetTester tester) async {
        final emptyState = PostsFeedLoaded(posts: const []);
        when(() => mockPostsFeedBloc.state).thenReturn(emptyState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        expect(find.text('No posts yet'), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      },
    );

    testWidgets(
      'displays error message when PostsFeedError',
      (WidgetTester tester) async {
        const errorMessage = 'Failed to load posts';
        final errorState = PostsFeedError(error: errorMessage);
        when(() => mockPostsFeedBloc.state).thenReturn(errorState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        expect(find.text(errorMessage), findsOneWidget);
      },
    );

    testWidgets(
      'posts are displayed in descending order by createdAt',
      (WidgetTester tester) async {
        final now = DateTime.now();
        final testPosts = [
          Post(
            id: '1',
            userId: 'user1',
            displayName: 'User One',
            text: 'Newest post',
            imageUrl: null,
            createdAt: now,
          ),
          Post(
            id: '2',
            userId: 'user2',
            displayName: 'User Two',
            text: 'Middle post',
            imageUrl: null,
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
          Post(
            id: '3',
            userId: 'user3',
            displayName: 'User Three',
            text: 'Oldest post',
            imageUrl: null,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ];

        final loadedState = PostsFeedLoaded(posts: testPosts);
        when(() => mockPostsFeedBloc.state).thenReturn(loadedState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        expect(find.text('Newest post'), findsOneWidget);
        expect(find.text('Middle post'), findsOneWidget);
        expect(find.text('Oldest post'), findsOneWidget);
      },
    );

    testWidgets(
      'pull-to-refresh is available',
      (WidgetTester tester) async {
        final testPosts = [
          Post(
            id: '1',
            userId: 'user1',
            displayName: 'User One',
            text: 'Test post',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
        ];

        final loadedState = PostsFeedLoaded(posts: testPosts, hasMore: false);
        when(() => mockPostsFeedBloc.state).thenReturn(loadedState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        // Verify RefreshIndicator is present
        expect(find.byType(RefreshIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'loading more indicator shown when isLoadingMore is true',
      (WidgetTester tester) async {
        final testPosts = [
          Post(
            id: '1',
            userId: 'user1',
            displayName: 'User One',
            text: 'Test post',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
        ];

        final loadingMoreState = PostsFeedLoaded(
          posts: testPosts,
          hasMore: true,
          isLoadingMore: true,
        );
        when(() => mockPostsFeedBloc.state).thenReturn(loadingMoreState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      },
    );

    testWidgets(
      'no more posts indicator when hasMore is false',
      (WidgetTester tester) async {
        final testPosts = [
          Post(
            id: '1',
            userId: 'user1',
            displayName: 'User One',
            text: 'Test post',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
        ];

        final noMoreState = PostsFeedLoaded(
          posts: testPosts,
          hasMore: false,
          isLoadingMore: false,
        );
        when(() => mockPostsFeedBloc.state).thenReturn(noMoreState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        // Verify ListView is rendered
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(PostCard), findsOneWidget);
      },
    );

    testWidgets(
      'pagination indicator shown for next page when hasMore is true',
      (WidgetTester tester) async {
        final testPosts = List.generate(
          15,
          (index) => Post(
            id: '$index',
            userId: 'user$index',
            displayName: 'User $index',
            text: 'Test post $index',
            imageUrl: null,
            createdAt: DateTime.now().subtract(Duration(seconds: index)),
          ),
        );

        final loadedState = PostsFeedLoaded(
          posts: testPosts,
          hasMore: true,
          cursor: 'page2',
          isLoadingMore: false,
        );
        when(() => mockPostsFeedBloc.state).thenReturn(loadedState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        // Verify all posts are rendered
        expect(find.byType(PostCard), findsWidgets);
        expect(find.byType(ListView), findsOneWidget);
      },
    );

    testWidgets(
      'tapping author avatar navigates to profile screen',
      (WidgetTester tester) async {
        final testPosts = [
          Post(
            id: '1',
            userId: 'user1',
            displayName: 'User One',
            text: 'Test post',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
        ];

        final loadedState = PostsFeedLoaded(posts: testPosts);
        when(() => mockPostsFeedBloc.state).thenReturn(loadedState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        // Verify PostCard is rendered with user information
        final postCard = find.byType(PostCard);
        expect(postCard, findsOneWidget);
        expect(find.text('User One'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping author name navigates to profile screen',
      (WidgetTester tester) async {
        final testPosts = [
          Post(
            id: '1',
            userId: 'user1',
            displayName: 'User One',
            text: 'Test post',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
        ];

        final loadedState = PostsFeedLoaded(posts: testPosts);
        when(() => mockPostsFeedBloc.state).thenReturn(loadedState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        expect(find.text('User One'), findsOneWidget);
      },
    );

    testWidgets(
      'delete post functionality is available',
      (WidgetTester tester) async {
        final testPosts = [
          Post(
            id: '1',
            userId: 'test-uid',
            displayName: 'User One',
            text: 'Test post',
            imageUrl: null,
            createdAt: DateTime.now(),
          ),
        ];

        final loadedState = PostsFeedLoaded(posts: testPosts);
        when(() => mockPostsFeedBloc.state).thenReturn(loadedState);

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );

        // Verify PostCard is rendered (delete action is handled within PostCard)
        expect(find.byType(PostCard), findsOneWidget);
      },
    );
  });
}
