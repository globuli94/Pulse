import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:pulse/features/notifications/presentation/bloc/unread_notifications_count_cubit.dart';

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  group('UnreadNotificationsCountCubit', () {
    late MockNotificationsRepository mockRepository;
    late UnreadNotificationsCountCubit cubit;

    setUp(() {
      mockRepository = MockNotificationsRepository();
      cubit = UnreadNotificationsCountCubit(
        repository: mockRepository,
        userId: 'test-user',
      );
    });

    tearDown(() {
      cubit.close();
    });

    test(
      'watchUnreadCount() with empty userId does not subscribe and stays at 0',
      () async {
        final emptyCubit = UnreadNotificationsCountCubit(
          repository: mockRepository,
          userId: '',
        );

        emptyCubit.watchUnreadCount();

        expect(emptyCubit.state, 0);
        verifyNever(() => mockRepository.watchUnreadCount(userId: any(named: 'userId')));

        await emptyCubit.close();
      },
    );

    blocTest<UnreadNotificationsCountCubit, int>(
      'watchUnreadCount() emits unread count from repository stream',
      build: () {
        when(() => mockRepository.watchUnreadCount(userId: 'test-user'))
            .thenAnswer((_) => Stream.value(3));
        return cubit;
      },
      act: (cubit) => cubit.watchUnreadCount(),
      expect: () => [3],
    );

    blocTest<UnreadNotificationsCountCubit, int>(
      'watchUnreadCount() with error stream emits 0',
      build: () {
        when(() => mockRepository.watchUnreadCount(userId: 'test-user'))
            .thenAnswer((_) => Stream.error(Exception('Error')));
        return cubit;
      },
      act: (cubit) => cubit.watchUnreadCount(),
      expect: () => [0],
    );

    test('close() cancels subscription', () async {
      final controller = StreamController<int>();
      when(() => mockRepository.watchUnreadCount(userId: 'test-user'))
          .thenAnswer((_) => controller.stream);

      cubit.watchUnreadCount();
      expect(cubit.isClosed, false);

      controller.add(5);
      await Future<void>.microtask(() {});
      expect(cubit.state, 5);

      await cubit.close();
      expect(cubit.isClosed, true);

      await controller.close();
    });

    group('startWatching', () {
      test('TC-4: startWatching with new userId subscribes to new userId\'s stream',
          () async {
        final cubatA = UnreadNotificationsCountCubit(
          repository: mockRepository,
          userId: 'user-A',
        );

        when(() => mockRepository.watchUnreadCount(userId: 'user-A'))
            .thenAnswer((_) => Stream.empty());
        when(() => mockRepository.watchUnreadCount(userId: 'user-B'))
            .thenAnswer((_) => Stream.value(4));

        cubatA.startWatching('user-B');
        await Future<void>.microtask(() {});

        expect(cubatA.state, 4);
        await cubatA.close();
      });

      test('TC-5: startWatching cancels prior subscription (no double-emit)',
          () async {
        final controllerA = StreamController<int>.broadcast();
        final controllerB = StreamController<int>.broadcast();

        when(() => mockRepository.watchUnreadCount(userId: 'user-A'))
            .thenAnswer((_) => controllerA.stream);
        when(() => mockRepository.watchUnreadCount(userId: 'user-B'))
            .thenAnswer((_) => controllerB.stream);

        final cubatA = UnreadNotificationsCountCubit(
          repository: mockRepository,
          userId: 'user-A',
        );

        cubatA.watchUnreadCount();
        controllerA.add(2);
        await Future<void>.microtask(() {});
        expect(cubatA.state, 2);

        cubatA.startWatching('user-B');
        controllerB.add(6);
        await Future<void>.microtask(() {});
        expect(cubatA.state, 6);

        controllerA.add(99);
        await Future<void>.microtask(() {});
        expect(cubatA.state, 6); // Should still be 6, not 99

        await controllerA.close();
        await controllerB.close();
        await cubatA.close();
      });

      test('TC-6: startWatching with empty userId does not subscribe',
          () async {
        final cubatA = UnreadNotificationsCountCubit(
          repository: mockRepository,
          userId: 'user-A',
        );

        cubatA.startWatching('');

        verifyNever(() => mockRepository.watchUnreadCount(userId: any(named: 'userId')));
        expect(cubatA.state, 0);
        await cubatA.close();
      });
    });
  });
}
