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
  });
}
