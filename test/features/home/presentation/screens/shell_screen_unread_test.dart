import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/bloc/unread_count_cubit.dart';
import 'package:pulse/features/home/presentation/bloc/shell_tab_cubit.dart';
import 'package:pulse/features/home/presentation/screens/shell_screen.dart';
import 'package:pulse/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:pulse/features/notifications/presentation/bloc/unread_notifications_count_cubit.dart';
import 'package:pulse/features/posts/presentation/bloc/posts_feed_bloc.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_posts_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockPostsFeedBloc extends MockBloc<PostsFeedEvent, PostsFeedState>
    implements PostsFeedBloc {}

class MockProfilePostsBloc
    extends MockBloc<ProfilePostsEvent, ProfilePostsState>
    implements ProfilePostsBloc {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

Widget _buildShell({
  required MockAuthBloc mockAuthBloc,
  required MockProfileBloc mockProfileBloc,
  required MockPostsFeedBloc mockPostsFeedBloc,
  required MockProfilePostsBloc mockProfilePostsBloc,
  required MockChatRepository mockChatRepository,
  required UnreadCountCubit unreadCountCubit,
  required MockNotificationsRepository mockNotificationsRepository,
  required UnreadNotificationsCountCubit unreadNotificationsCubit,
  required ShellTabCubit shellTabCubit,
}) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const ShellScreen(),
      ),
    ],
  );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ChatRepository>(create: (_) => mockChatRepository),
      RepositoryProvider<NotificationsRepository>(
          create: (_) => mockNotificationsRepository),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<ShellTabCubit>.value(value: shellTabCubit),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
        BlocProvider<PostsFeedBloc>.value(value: mockPostsFeedBloc),
        BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
        BlocProvider<UnreadCountCubit>.value(value: unreadCountCubit),
        BlocProvider<UnreadNotificationsCountCubit>.value(
            value: unreadNotificationsCubit),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('ShellScreen — Badge Rendering', () {
    late MockAuthBloc mockAuthBloc;
    late MockProfileBloc mockProfileBloc;
    late MockPostsFeedBloc mockPostsFeedBloc;
    late MockProfilePostsBloc mockProfilePostsBloc;
    late MockChatRepository mockChatRepository;
    late MockNotificationsRepository mockNotificationsRepository;
    late ShellTabCubit shellTabCubit;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockProfileBloc = MockProfileBloc();
      mockPostsFeedBloc = MockPostsFeedBloc();
      mockProfilePostsBloc = MockProfilePostsBloc();
      mockChatRepository = MockChatRepository();
      mockNotificationsRepository = MockNotificationsRepository();
      shellTabCubit = ShellTabCubit();

      when(() => mockChatRepository.watchConversations(any()))
          .thenAnswer((_) => const Stream.empty());

      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => Stream.value(Authenticated(testUser)));

      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      when(() => mockProfileBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      when(() => mockPostsFeedBloc.state).thenReturn(const PostsFeedLoading());
      when(() => mockPostsFeedBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      when(() => mockProfilePostsBloc.state)
          .thenReturn(const ProfilePostsInitial());
      when(() => mockProfilePostsBloc.stream)
          .thenAnswer((_) => const Stream.empty());
    });

    testWidgets(
        'TC-7: Messages tab shows Badge when UnreadCountCubit emits > 0',
        (WidgetTester tester) async {
      final unreadCountCubit = UnreadCountCubit(
        repository: mockChatRepository,
        currentUserId: 'test-user',
      );
      final unreadNotificationsCubit = UnreadNotificationsCountCubit(
        repository: mockNotificationsRepository,
        userId: 'test-user',
      );

      await tester.pumpWidget(
        _buildShell(
          mockAuthBloc: mockAuthBloc,
          mockProfileBloc: mockProfileBloc,
          mockPostsFeedBloc: mockPostsFeedBloc,
          mockProfilePostsBloc: mockProfilePostsBloc,
          mockChatRepository: mockChatRepository,
          unreadCountCubit: unreadCountCubit,
          mockNotificationsRepository: mockNotificationsRepository,
          unreadNotificationsCubit: unreadNotificationsCubit,
          shellTabCubit: shellTabCubit,
        ),
      );

      // Emit 3 unread messages
      unreadCountCubit.emit(3);
      await tester.pump();

      expect(find.byType(Badge), findsWidgets);

      await unreadCountCubit.close();
      await unreadNotificationsCubit.close();
    });

    testWidgets(
        'TC-8: Messages tab shows no Badge when UnreadCountCubit emits 0',
        (WidgetTester tester) async {
      final unreadCountCubit = UnreadCountCubit(
        repository: mockChatRepository,
        currentUserId: 'test-user',
      );
      final unreadNotificationsCubit = UnreadNotificationsCountCubit(
        repository: mockNotificationsRepository,
        userId: 'test-user',
      );

      await tester.pumpWidget(
        _buildShell(
          mockAuthBloc: mockAuthBloc,
          mockProfileBloc: mockProfileBloc,
          mockPostsFeedBloc: mockPostsFeedBloc,
          mockProfilePostsBloc: mockProfilePostsBloc,
          mockChatRepository: mockChatRepository,
          unreadCountCubit: unreadCountCubit,
          mockNotificationsRepository: mockNotificationsRepository,
          unreadNotificationsCubit: unreadNotificationsCubit,
          shellTabCubit: shellTabCubit,
        ),
      );

      // Emit 0 unread messages
      unreadCountCubit.emit(0);
      await tester.pump();

      expect(find.byType(Badge), findsNothing);

      await unreadCountCubit.close();
      await unreadNotificationsCubit.close();
    });

    testWidgets(
        'TC-9: Bell icon shows Badge when UnreadNotificationsCountCubit emits > 0',
        (WidgetTester tester) async {
      final unreadCountCubit = UnreadCountCubit(
        repository: mockChatRepository,
        currentUserId: 'test-user',
      );
      final unreadNotificationsCubit = UnreadNotificationsCountCubit(
        repository: mockNotificationsRepository,
        userId: 'test-user',
      );

      await tester.pumpWidget(
        _buildShell(
          mockAuthBloc: mockAuthBloc,
          mockProfileBloc: mockProfileBloc,
          mockPostsFeedBloc: mockPostsFeedBloc,
          mockProfilePostsBloc: mockProfilePostsBloc,
          mockChatRepository: mockChatRepository,
          unreadCountCubit: unreadCountCubit,
          mockNotificationsRepository: mockNotificationsRepository,
          unreadNotificationsCubit: unreadNotificationsCubit,
          shellTabCubit: shellTabCubit,
        ),
      );

      // Emit 5 unread notifications
      unreadNotificationsCubit.emit(5);
      await tester.pump();

      expect(find.byType(Badge), findsWidgets);

      await unreadCountCubit.close();
      await unreadNotificationsCubit.close();
    });

    testWidgets(
        'TC-10: Bell icon shows no Badge when UnreadNotificationsCountCubit emits 0',
        (WidgetTester tester) async {
      final unreadCountCubit = UnreadCountCubit(
        repository: mockChatRepository,
        currentUserId: 'test-user',
      );
      final unreadNotificationsCubit = UnreadNotificationsCountCubit(
        repository: mockNotificationsRepository,
        userId: 'test-user',
      );

      await tester.pumpWidget(
        _buildShell(
          mockAuthBloc: mockAuthBloc,
          mockProfileBloc: mockProfileBloc,
          mockPostsFeedBloc: mockPostsFeedBloc,
          mockProfilePostsBloc: mockProfilePostsBloc,
          mockChatRepository: mockChatRepository,
          unreadCountCubit: unreadCountCubit,
          mockNotificationsRepository: mockNotificationsRepository,
          unreadNotificationsCubit: unreadNotificationsCubit,
          shellTabCubit: shellTabCubit,
        ),
      );

      // Emit 0 unread notifications
      unreadNotificationsCubit.emit(0);
      await tester.pump();

      expect(find.byType(Badge), findsNothing);

      await unreadCountCubit.close();
      await unreadNotificationsCubit.close();
    });
  });
}
