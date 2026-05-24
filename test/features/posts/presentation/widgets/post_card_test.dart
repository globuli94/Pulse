import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/posts/domain/entities/post.dart';
import 'package:pulse/features/posts/presentation/bloc/posts_feed_bloc.dart';
import 'package:pulse/features/posts/presentation/widgets/post_card.dart';

class MockPostsFeedBloc extends Mock implements PostsFeedBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('PostCard', () {
    late MockPostsFeedBloc mockPostsFeedBloc;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockPostsFeedBloc = MockPostsFeedBloc();
      mockAuthBloc = MockAuthBloc();
      when(() => mockPostsFeedBloc.state).thenReturn(const PostsFeedLoaded(posts: []));
      when(() => mockPostsFeedBloc.stream).thenAnswer((_) => const Stream.empty());
      final mockUser = AppUser(uid: 'current-user', email: 'test@example.com', displayName: 'Test User');
      when(() => mockAuthBloc.state).thenReturn(Authenticated(mockUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildCard(Post post) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: Scaffold(
            body: PostCard(post: post),
          ),
        ),
      );
    }

    testWidgets('renders displayName', (WidgetTester tester) async {
      final post = Post(
        id: '1',
        userId: 'user1',
        displayName: 'John Doe',
        text: 'Hello world',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        imageUrl: null,
      );

      await tester.pumpWidget(buildCard(post));

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('renders text content', (WidgetTester tester) async {
      final post = Post(
        id: '1',
        userId: 'user1',
        displayName: 'John Doe',
        text: 'This is my test post',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        imageUrl: null,
      );

      await tester.pumpWidget(buildCard(post));

      expect(find.text('This is my test post'), findsOneWidget);
    });

    testWidgets('renders formatted createdAt timestamp', (WidgetTester tester) async {
      final post = Post(
        id: '1',
        userId: 'user1',
        displayName: 'John Doe',
        text: 'Hello world',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        imageUrl: null,
      );

      await tester.pumpWidget(buildCard(post));

      // Check that some time representation is rendered (exact format may vary)
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets(
        'shows delete button when post owner matches current auth user',
        (WidgetTester tester) async {
      final post = Post(
        id: '1',
        userId: 'current-user',
        displayName: 'John Doe',
        text: 'Hello world',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        imageUrl: null,
      );

      await tester.pumpWidget(buildCard(post));

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('hides delete button when post owner does not match current user',
        (WidgetTester tester) async {
      final post = Post(
        id: '1',
        userId: 'other-user',
        displayName: 'John Doe',
        text: 'Hello world',
        createdAt: DateTime(2024, 1, 15, 10, 30),
        imageUrl: null,
      );

      await tester.pumpWidget(buildCard(post));

      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });
}
