import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/notifications/domain/entities/notification_item.dart';
import 'package:pulse/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:pulse/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:pulse/features/notifications/presentation/screens/notifications_screen.dart';

class MockNotificationsBloc extends Mock implements NotificationsBloc {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class FakeNotificationsEvent extends Fake implements NotificationsEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeNotificationsEvent());
  });

  group('NotificationsScreen', () {
    late MockNotificationsBloc mockBloc;
    late MockNotificationsRepository mockRepository;

    setUp(() {
      mockBloc = MockNotificationsBloc();
      mockRepository = MockNotificationsRepository();
      when(() => mockRepository.watchActorPhotoUrl(actorId: any(named: 'actorId')))
          .thenAnswer((_) => const Stream.empty());
    });

    testWidgets(
      'shows loading indicator when NotificationsInitial',
      (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(const NotificationsInitial());
        when(() => mockBloc.stream)
            .thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            home: RepositoryProvider<NotificationsRepository>(
              create: (_) => mockRepository,
              child: BlocProvider<NotificationsBloc>.value(
                value: mockBloc,
                child: const NotificationsScreen(),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'shows loading indicator when NotificationsLoading',
      (WidgetTester tester) async {
        when(() => mockBloc.state).thenReturn(const NotificationsLoading());
        when(() => mockBloc.stream)
            .thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            home: RepositoryProvider<NotificationsRepository>(
              create: (_) => mockRepository,
              child: BlocProvider<NotificationsBloc>.value(
                value: mockBloc,
                child: const NotificationsScreen(),
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'shows "No notifications yet." when NotificationsLoaded with empty list',
      (WidgetTester tester) async {
        when(() => mockBloc.state)
            .thenReturn(const NotificationsLoaded(notifications: []));
        when(() => mockBloc.stream)
            .thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            home: RepositoryProvider<NotificationsRepository>(
              create: (_) => mockRepository,
              child: BlocProvider<NotificationsBloc>.value(
                value: mockBloc,
                child: const NotificationsScreen(),
              ),
            ),
          ),
        );

        expect(find.text('No notifications yet.'), findsOneWidget);
      },
    );

    testWidgets(
      'tile shows actor photo when watchActorPhotoUrl emits a URL',
      (WidgetTester tester) async {
        final testNotifications = [
          NotificationItem(
            id: '1',
            userId: 'test-user',
            type: 'like',
            actorId: 'actor-1',
            actorDisplayName: 'Alice',
            postId: 'post-1',
            isRead: false,
            createdAt: DateTime(2026, 5, 26),
          ),
        ];

        when(() => mockBloc.state)
            .thenReturn(NotificationsLoaded(notifications: testNotifications));
        when(() => mockBloc.stream)
            .thenAnswer((_) => const Stream.empty());
        when(() => mockRepository.watchActorPhotoUrl(actorId: 'actor-1'))
            .thenAnswer((_) => Stream.value('https://example.com/alice.jpg'));

        await tester.pumpWidget(
          MaterialApp(
            home: RepositoryProvider<NotificationsRepository>(
              create: (_) => mockRepository,
              child: BlocProvider<NotificationsBloc>.value(
                value: mockBloc,
                child: const NotificationsScreen(),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CircleAvatar &&
                widget.backgroundImage is NetworkImage,
          ),
          findsOneWidget,
        );
      },
    );

  });
}
