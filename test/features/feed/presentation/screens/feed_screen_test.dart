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
  });
}
