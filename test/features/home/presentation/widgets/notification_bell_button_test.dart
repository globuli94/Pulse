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

class MockUnreadCountCubit extends MockCubit<int> implements UnreadCountCubit {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockUnreadNotificationsCountCubit extends MockCubit<int>
    implements UnreadNotificationsCountCubit {}

Widget _buildShell({
  required MockAuthBloc mockAuthBloc,
  required MockProfileBloc mockProfileBloc,
  required MockPostsFeedBloc mockPostsFeedBloc,
  required MockProfilePostsBloc mockProfilePostsBloc,
  required MockChatRepository mockChatRepository,
  required MockUnreadCountCubit mockUnreadCountCubit,
  required MockNotificationsRepository mockNotificationsRepository,
  required MockUnreadNotificationsCountCubit mockUnreadNotificationsCountCubit,
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
        BlocProvider<UnreadCountCubit>.value(value: mockUnreadCountCubit),
        BlocProvider<UnreadNotificationsCountCubit>.value(
            value: mockUnreadNotificationsCountCubit),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  group('NotificationBellButton — clipBehavior', () {
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
        'renders Stack with clipBehavior: Clip.none when unreadCount > 0',
        (tester) async {
      when(() => mockUnreadNotificationsCountCubit.state).thenReturn(5);
      when(() => mockUnreadNotificationsCountCubit.stream)
          .thenAnswer((_) => Stream.value(5));

      await tester.pumpWidget(_buildShell(
        mockAuthBloc: mockAuthBloc,
        mockProfileBloc: mockProfileBloc,
        mockPostsFeedBloc: mockPostsFeedBloc,
        mockProfilePostsBloc: mockProfilePostsBloc,
        mockChatRepository: mockChatRepository,
        mockUnreadCountCubit: mockUnreadCountCubit,
        mockNotificationsRepository: mockNotificationsRepository,
        mockUnreadNotificationsCountCubit: mockUnreadNotificationsCountCubit,
        shellTabCubit: shellTabCubit,
      ));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
            (w) => w is Stack && w.clipBehavior == Clip.none),
        findsWidgets,
        reason: 'Stack with clipBehavior: Clip.none must exist when unread > 0',
      );
    });

    testWidgets(
        'renders no Stack with clipBehavior: Clip.none when unreadCount is 0',
        (tester) async {
      when(() => mockUnreadNotificationsCountCubit.state).thenReturn(0);
      when(() => mockUnreadNotificationsCountCubit.stream)
          .thenAnswer((_) => Stream.value(0));

      await tester.pumpWidget(_buildShell(
        mockAuthBloc: mockAuthBloc,
        mockProfileBloc: mockProfileBloc,
        mockPostsFeedBloc: mockPostsFeedBloc,
        mockProfilePostsBloc: mockProfilePostsBloc,
        mockChatRepository: mockChatRepository,
        mockUnreadCountCubit: mockUnreadCountCubit,
        mockNotificationsRepository: mockNotificationsRepository,
        mockUnreadNotificationsCountCubit: mockUnreadNotificationsCountCubit,
        shellTabCubit: shellTabCubit,
      ));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
            (w) => w is Stack && w.clipBehavior == Clip.none),
        findsNothing,
        reason:
            'No Stack with clipBehavior: Clip.none should exist when unread == 0',
      );
    });

    testWidgets('updates widget tree when unreadCount changes from 0 to > 0',
        (tester) async {
      final streamController = StreamController<int>.broadcast();

      when(() => mockUnreadNotificationsCountCubit.state).thenReturn(0);
      when(() => mockUnreadNotificationsCountCubit.stream)
          .thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(_buildShell(
        mockAuthBloc: mockAuthBloc,
        mockProfileBloc: mockProfileBloc,
        mockPostsFeedBloc: mockPostsFeedBloc,
        mockProfilePostsBloc: mockProfilePostsBloc,
        mockChatRepository: mockChatRepository,
        mockUnreadCountCubit: mockUnreadCountCubit,
        mockNotificationsRepository: mockNotificationsRepository,
        mockUnreadNotificationsCountCubit: mockUnreadNotificationsCountCubit,
        shellTabCubit: shellTabCubit,
      ));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
            (w) => w is Stack && w.clipBehavior == Clip.none),
        findsNothing,
        reason: 'No clipped Stack before any unread notifications',
      );

      streamController.add(3);
      await tester.pump();
      await tester.pump();

      expect(
        find.byWidgetPredicate(
            (w) => w is Stack && w.clipBehavior == Clip.none),
        findsWidgets,
        reason: 'Stack with Clip.none must appear after unreadCount emits > 0',
      );

      await streamController.close();
    });
  });
}
