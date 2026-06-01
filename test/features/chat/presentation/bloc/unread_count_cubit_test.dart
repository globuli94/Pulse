import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/chat/domain/entities/conversation.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/bloc/unread_count_cubit.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late UnreadCountCubit unreadCountCubit;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    unreadCountCubit = UnreadCountCubit(
      repository: mockChatRepository,
      currentUserId: 'user1',
    );
  });

  tearDown(() {
    unreadCountCubit.close();
  });

  group('UnreadCountCubit', () {
    test('initial state is 0', () {
      expect(unreadCountCubit.state, 0);
    });

    blocTest<UnreadCountCubit, int>(
      'emits sum of unread counts for current user when watchUnreadCount is called',
      setUp: () {
        when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
          (_) => Stream.value([
            Conversation(
              id: 'conv1',
              participantIds: ['user1', 'user2'],
              otherUserDisplayName: 'John Doe',
              lastMessageText: 'Hello',
              lastMessageAt: DateTime.now(),
              unreadCounts: {'user1': 3},
            ),
            Conversation(
              id: 'conv2',
              participantIds: ['user1', 'user3'],
              otherUserDisplayName: 'Jane Smith',
              lastMessageText: 'Hi',
              lastMessageAt: DateTime.now(),
              unreadCounts: {'user1': 2},
            ),
          ]),
        );
      },
      build: () => unreadCountCubit,
      act: (cubit) => cubit.watchUnreadCount(),
      expect: () => [5],
    );

    blocTest<UnreadCountCubit, int>(
      'emits 0 when no conversations have unread messages',
      setUp: () {
        when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
          (_) => Stream.value([
            Conversation(
              id: 'conv1',
              participantIds: ['user1', 'user2'],
              otherUserDisplayName: 'John Doe',
              lastMessageText: 'Hello',
              lastMessageAt: DateTime.now(),
              unreadCounts: {'user1': 0},
            ),
          ]),
        );
      },
      build: () => unreadCountCubit,
      act: (cubit) => cubit.watchUnreadCount(),
      expect: () => [0],
    );

    blocTest<UnreadCountCubit, int>(
      'emits 0 when stream errors',
      setUp: () {
        when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
          (_) => Stream.error(Exception('Network error')),
        );
      },
      build: () => unreadCountCubit,
      act: (cubit) => cubit.watchUnreadCount(),
      expect: () => [0],
    );

    group('startWatching', () {
      test('TC-1: startWatching with new userId subscribes to new userId\'s stream',
          () async {
        final cubitA =
            UnreadCountCubit(repository: mockChatRepository, currentUserId: 'user-A');

        when(() => mockChatRepository.watchConversations('user-A'))
            .thenAnswer((_) => Stream.empty());
        when(() => mockChatRepository.watchConversations('user-B')).thenAnswer(
          (_) => Stream.value([
            Conversation(
              id: 'conv1',
              participantIds: ['user-B', 'other'],
              otherUserDisplayName: 'Test User',
              lastMessageText: 'Hello',
              lastMessageAt: DateTime.now(),
              unreadCounts: {'user-B': 7},
            ),
          ]),
        );

        cubitA.startWatching('user-B');
        await Future<void>.microtask(() {});

        expect(cubitA.state, 7);
        await cubitA.close();
      });

      test('TC-2: startWatching cancels prior subscription (no double-emit)',
          () async {
        final controllerA =
            StreamController<List<Conversation>>.broadcast();
        final controllerB =
            StreamController<List<Conversation>>.broadcast();

        when(() => mockChatRepository.watchConversations('user-A'))
            .thenAnswer((_) => controllerA.stream);
        when(() => mockChatRepository.watchConversations('user-B'))
            .thenAnswer((_) => controllerB.stream);

        final cubitA =
            UnreadCountCubit(repository: mockChatRepository, currentUserId: 'user-A');

        cubitA.watchUnreadCount();
        controllerA.add([
          Conversation(
            id: 'conv1',
            participantIds: ['user-A', 'other'],
            otherUserDisplayName: 'Test User',
            lastMessageText: 'Hello',
            lastMessageAt: DateTime.now(),
            unreadCounts: {'user-A': 3},
          ),
        ]);
        await Future<void>.microtask(() {});
        expect(cubitA.state, 3);

        cubitA.startWatching('user-B');
        controllerB.add([
          Conversation(
            id: 'conv2',
            participantIds: ['user-B', 'other'],
            otherUserDisplayName: 'Test User',
            lastMessageText: 'Hi',
            lastMessageAt: DateTime.now(),
            unreadCounts: {'user-B': 5},
          ),
        ]);
        await Future<void>.microtask(() {});
        expect(cubitA.state, 5);

        controllerA.add([
          Conversation(
            id: 'conv1',
            participantIds: ['user-A', 'other'],
            otherUserDisplayName: 'Test User',
            lastMessageText: 'Hello',
            lastMessageAt: DateTime.now(),
            unreadCounts: {'user-A': 99},
          ),
        ]);
        await Future<void>.microtask(() {});
        expect(cubitA.state, 5); // Should still be 5, not 99

        await controllerA.close();
        await controllerB.close();
        await cubitA.close();
      });

      test('TC-3: startWatching with empty userId does not subscribe',
          () async {
        final cubitA =
            UnreadCountCubit(repository: mockChatRepository, currentUserId: 'user-A');

        cubitA.startWatching('');

        verifyNever(
            () => mockChatRepository.watchConversations(any()));
        expect(cubitA.state, 0);
        await cubitA.close();
      });
    });
  });
}
