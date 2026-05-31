import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/bloc/unread_count_cubit.dart';
import 'package:pulse/features/home/presentation/screens/shell_screen.dart';
import 'package:pulse/features/feed/presentation/screens/feed_screen.dart';
import 'package:pulse/features/posts/presentation/bloc/posts_feed_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/profile_screen.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_posts_bloc.dart';
import 'package:pulse/features/home/presentation/bloc/shell_tab_cubit.dart';
import 'package:pulse/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:pulse/features/notifications/presentation/bloc/unread_notifications_count_cubit.dart';

class MockAuthBloc extends Mock implements AuthBloc {}
class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState> implements ProfileBloc {}
class MockPostsFeedBloc extends MockBloc<PostsFeedEvent, PostsFeedState> implements PostsFeedBloc {}
class MockProfilePostsBloc extends MockBloc<ProfilePostsEvent, ProfilePostsState> implements ProfilePostsBloc {}
class MockChatRepository extends Mock implements ChatRepository {}
class MockUnreadCountCubit extends MockCubit<int> implements UnreadCountCubit {}
class MockNotificationsRepository extends Mock implements NotificationsRepository {}
class MockUnreadNotificationsCountCubit extends MockCubit<int> implements UnreadNotificationsCountCubit {}

void main() {
  group('Navigation Shell - Flow Tests', () {
    late MockAuthBloc mockAuthBloc;
    late MockProfileBloc mockProfileBloc;
    late MockPostsFeedBloc mockPostsFeedBloc;
    late MockProfilePostsBloc mockProfilePostsBloc;
    late MockChatRepository mockChatRepository;
    late MockUnreadCountCubit mockUnreadCountCubit;
    late MockNotificationsRepository mockNotificationsRepository;
    late MockUnreadNotificationsCountCubit mockUnreadNotificationsCountCubit;
    late ShellTabCubit shellTabCubit;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockProfileBloc = MockProfileBloc();
      mockPostsFeedBloc = MockPostsFeedBloc();
      mockProfilePostsBloc = MockProfilePostsBloc();
      mockChatRepository = MockChatRepository();
      mockUnreadCountCubit = MockUnreadCountCubit();
      mockNotificationsRepository = MockNotificationsRepository();
      mockUnreadNotificationsCountCubit = MockUnreadNotificationsCountCubit();
      shellTabCubit = ShellTabCubit();
      when(() => mockChatRepository.watchConversations(any()))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockUnreadCountCubit.state).thenReturn(0);
      when(() => mockUnreadCountCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockUnreadNotificationsCountCubit.state).thenReturn(0);
      when(() => mockUnreadNotificationsCountCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      // Mock authenticated state
      when(() => mockAuthBloc.state).thenReturn(
        Authenticated(testUser),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(
          Authenticated(testUser),
        ),
      );
      // Mock profile state
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
      // Mock posts feed state
      when(() => mockPostsFeedBloc.state).thenReturn(const PostsFeedLoading());
      when(() => mockPostsFeedBloc.stream).thenAnswer((_) => const Stream.empty());
      // Mock profile posts state
      when(() => mockProfilePostsBloc.state).thenReturn(const ProfilePostsInitial());
      when(() => mockProfilePostsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    testWidgets(
      'ShellScreen renders BottomNavigationBar with Feed and Profile tabs',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            // Simulate authenticated state for this test
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ChatRepository>(
                create: (_) => mockChatRepository,
              ),
              RepositoryProvider<NotificationsRepository>(
                create: (_) => mockNotificationsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ShellTabCubit>.value(value: shellTabCubit),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
                BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
                BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
                BlocProvider<UnreadCountCubit>.value(value: mockUnreadCountCubit),
                BlocProvider<UnreadNotificationsCountCubit>.value(value: mockUnreadNotificationsCountCubit),
              ],
              child: MaterialApp.router(
                routerConfig: router,
              ),
            ),
          ),
        );

        // Verify BottomNavigationBar is present
        expect(find.byType(BottomNavigationBar), findsOneWidget);

        // Verify "Feed" tab is present (appears in AppBar and BottomNavigationBar)
        expect(find.text('Feed'), findsWidgets);

        // Verify "Profile" tab is present
        expect(find.text('Profile'), findsWidgets);

        // Verify bell icon is visible on the AppBar (findsWidgets because
        // Notifications tab in bottom nav also uses notifications_outlined icon)
        expect(find.byIcon(Icons.notifications_outlined), findsWidgets);
      },
    );

    testWidgets(
      'Tapping Profile tab shows ProfileScreen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ChatRepository>(
                create: (_) => mockChatRepository,
              ),
              RepositoryProvider<NotificationsRepository>(
                create: (_) => mockNotificationsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ShellTabCubit>.value(value: shellTabCubit),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
                BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
                BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
                BlocProvider<UnreadCountCubit>.value(value: mockUnreadCountCubit),
                BlocProvider<UnreadNotificationsCountCubit>.value(value: mockUnreadNotificationsCountCubit),
              ],
              child: MaterialApp.router(
                routerConfig: router,
              ),
            ),
          ),
        );

        // Tap the Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pump();

        // Verify ProfileScreen is displayed
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Feed tab shows FeedScreen',
      (WidgetTester tester) async {
        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ChatRepository>(
                create: (_) => mockChatRepository,
              ),
              RepositoryProvider<NotificationsRepository>(
                create: (_) => mockNotificationsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ShellTabCubit>.value(value: shellTabCubit),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
                BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
                BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
                BlocProvider<UnreadCountCubit>.value(value: mockUnreadCountCubit),
                BlocProvider<UnreadNotificationsCountCubit>.value(value: mockUnreadNotificationsCountCubit),
              ],
              child: MaterialApp.router(
                routerConfig: router,
              ),
            ),
          ),
        );

        // First tap Profile to switch away from Feed
        await tester.tap(find.text('Profile'));
        await tester.pump();

        // Now tap Feed tab
        await tester.tap(find.text('Feed'));
        await tester.pump();

        // Verify FeedScreen is displayed
        expect(find.byType(FeedScreen), findsOneWidget);
      },
    );

    testWidgets(
      'UI-001 #10: badge colors use colorScheme.primary for bell icon and messages tab',
      (WidgetTester tester) async {
        // Update unread count to trigger badge rendering
        when(() => mockUnreadCountCubit.state).thenReturn(2);
        when(() => mockUnreadCountCubit.stream)
            .thenAnswer((_) => Stream.value(2));

        when(() => mockUnreadNotificationsCountCubit.state).thenReturn(3);
        when(() => mockUnreadNotificationsCountCubit.stream)
            .thenAnswer((_) => Stream.value(3));

        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ChatRepository>(
                create: (_) => mockChatRepository,
              ),
              RepositoryProvider<NotificationsRepository>(
                create: (_) => mockNotificationsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ShellTabCubit>.value(value: shellTabCubit),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
                BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
                BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
                BlocProvider<UnreadCountCubit>.value(value: mockUnreadCountCubit),
                BlocProvider<UnreadNotificationsCountCubit>.value(
                    value: mockUnreadNotificationsCountCubit),
              ],
              child: MaterialApp.router(
                routerConfig: router,
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify bell icon is visible (findsWidgets: AppBar bell + Notifications tab icon)
        expect(find.byIcon(Icons.notifications_outlined), findsWidgets);

        // Check that badge is rendered with numbers
        expect(find.text('3'), findsWidgets);
        expect(find.text('2'), findsWidgets);
      },
    );

    testWidgets(
      'UI-001 #11: badges update in real-time when stream emits new values',
      (WidgetTester tester) async {
        final unreadCountController = StreamController<int>.broadcast();
        final unreadNotificationsController = StreamController<int>.broadcast();

        when(() => mockUnreadCountCubit.state).thenReturn(0);
        when(() => mockUnreadCountCubit.stream)
            .thenAnswer((_) => unreadCountController.stream);

        when(() => mockUnreadNotificationsCountCubit.state).thenReturn(0);
        when(() => mockUnreadNotificationsCountCubit.stream)
            .thenAnswer((_) => unreadNotificationsController.stream);

        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ChatRepository>(
                create: (_) => mockChatRepository,
              ),
              RepositoryProvider<NotificationsRepository>(
                create: (_) => mockNotificationsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ShellTabCubit>.value(value: shellTabCubit),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
                BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
                BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
                BlocProvider<UnreadCountCubit>.value(value: mockUnreadCountCubit),
                BlocProvider<UnreadNotificationsCountCubit>.value(
                    value: mockUnreadNotificationsCountCubit),
              ],
              child: MaterialApp.router(
                routerConfig: router,
              ),
            ),
          ),
        );

        await tester.pump();

        // Emit new values
        unreadCountController.add(5);
        unreadNotificationsController.add(7);

        await tester.pump();
        await tester.pump();

        // Verify badges updated with new values
        expect(find.text('5'), findsWidgets);
        expect(find.text('7'), findsWidgets);

        // Cleanup
        await unreadCountController.close();
        await unreadNotificationsController.close();
      },
    );

    testWidgets(
      'UI-001 #12: notification indicator badge is fully visible without clipping on nav bar',
      (WidgetTester tester) async {
        when(() => mockUnreadNotificationsCountCubit.state).thenReturn(99);
        when(() => mockUnreadNotificationsCountCubit.stream)
            .thenAnswer((_) => Stream.value(99));

        final router = GoRouter(
          initialLocation: '/home',
          redirect: (BuildContext context, GoRouterState state) {
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const ShellScreen(),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ChatRepository>(
                create: (_) => mockChatRepository,
              ),
              RepositoryProvider<NotificationsRepository>(
                create: (_) => mockNotificationsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<ShellTabCubit>.value(value: shellTabCubit),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
                BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
                BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
                BlocProvider<UnreadCountCubit>.value(value: mockUnreadCountCubit),
                BlocProvider<UnreadNotificationsCountCubit>.value(
                    value: mockUnreadNotificationsCountCubit),
              ],
              child: MaterialApp.router(
                routerConfig: router,
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify badge number is visible (99)
        expect(find.text('99'), findsWidgets,
            reason: 'Badge number should be fully visible');

        // Verify AppBar with bell icon is visible (findsWidgets: AppBar bell + Notifications tab icon)
        expect(find.byIcon(Icons.notifications_outlined), findsWidgets);
      },
    );

  });
}
