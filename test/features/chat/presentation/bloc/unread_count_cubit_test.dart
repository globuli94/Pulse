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
  });
}
