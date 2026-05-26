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

  // Helper function to create test notification
  NotificationItem _createTestNotification({
    required String id,
    required String type,
    required String actorDisplayName,
    String? postId,
    bool isRead = false,
  }) {
    return NotificationItem(
      id: id,
      userId: 'test-user',
      type: type,
      actorId: 'actor-${id}',
      actorDisplayName: actorDisplayName,
      actorPhotoUrl: '', // Empty to avoid network image loading in tests
      postId: postId,
      isRead: isRead,
      createdAt: DateTime(2026, 5, 26),
    );
  }

  group('NotificationsScreen', () {
    late MockNotificationsBloc mockBloc;
    late MockNotificationsRepository mockRepository;

    setUp(() {
      mockBloc = MockNotificationsBloc();
      mockRepository = MockNotificationsRepository();
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

  });
}
