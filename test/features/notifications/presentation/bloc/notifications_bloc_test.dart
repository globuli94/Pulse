import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/notifications/domain/entities/notification_item.dart';
import 'package:pulse/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:pulse/features/notifications/presentation/bloc/notifications_bloc.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  group('NotificationsBloc', () {
    late MockNotificationsRepository mockRepository;

    setUp(() {
      mockRepository = MockNotificationsRepository();
    });

    group('NotificationsSubscriptionRequested', () {
      blocTest<NotificationsBloc, NotificationsState>(
        'emits [NotificationsLoading, NotificationsLoaded] on successful subscription',
        build: () {
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

          when(() => mockRepository.watchNotifications(userId: 'test-user'))
              .thenAnswer((_) => Stream.value(testNotifications));

          return NotificationsBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const NotificationsSubscriptionRequested(userId: 'test-user'),
        ),
        expect: () => [
          isA<NotificationsLoading>(),
          isA<NotificationsLoaded>()
              .having(
                (state) => state.notifications,
                'notifications',
                hasLength(1),
              ),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'emits [NotificationsLoading, NotificationsError] on repository error',
        build: () {
          when(() => mockRepository.watchNotifications(userId: 'test-user'))
              .thenAnswer((_) => Stream.error(Exception('Network error')));

          return NotificationsBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const NotificationsSubscriptionRequested(userId: 'test-user'),
        ),
        expect: () => [
          isA<NotificationsLoading>(),
          isA<NotificationsError>()
              .having(
                (state) => state.message,
                'message',
                contains('Network error'),
              ),
        ],
      );

      blocTest<NotificationsBloc, NotificationsState>(
        'emits [NotificationsLoading, NotificationsLoaded] with empty list',
        build: () {
          when(() => mockRepository.watchNotifications(userId: 'test-user'))
              .thenAnswer((_) => Stream.value([]));

          return NotificationsBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const NotificationsSubscriptionRequested(userId: 'test-user'),
        ),
        expect: () => [
          isA<NotificationsLoading>(),
          isA<NotificationsLoaded>()
              .having(
                (state) => state.notifications,
                'notifications',
                isEmpty,
              ),
        ],
      );
    });

    group('NotificationMarkReadRequested', () {
      blocTest<NotificationsBloc, NotificationsState>(
        'calls repository.markAsRead exactly once with correct notificationId',
        build: () {
          when(() => mockRepository.markAsRead(notificationId: 'notif-123'))
              .thenAnswer((_) async {});

          return NotificationsBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(
          const NotificationMarkReadRequested(notificationId: 'notif-123'),
        ),
        verify: (bloc) {
          verify(
            () => mockRepository.markAsRead(notificationId: 'notif-123'),
          ).called(1);
        },
      );
    });
  });
}
