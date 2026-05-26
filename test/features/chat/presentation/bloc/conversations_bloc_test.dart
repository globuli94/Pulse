import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/chat/domain/entities/conversation.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/bloc/conversations_bloc.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late ConversationsBloc conversationsBloc;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    conversationsBloc = ConversationsBloc(
      repository: mockChatRepository,
    );
  });

  tearDown(() {
    conversationsBloc.close();
  });

  group('ConversationsBloc', () {
    test('initial state is ConversationsInitial', () {
      expect(conversationsBloc.state, isA<ConversationsInitial>());
    });

    blocTest<ConversationsBloc, ConversationsState>(
      'emits ConversationsLoading then ConversationsLoaded when ConversationsStarted is added',
      setUp: () {
        when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
          (_) => Stream.value([
            Conversation(
              id: 'conv1',
              participantIds: ['user1', 'user2'],
              otherUserDisplayName: 'John Doe',
              lastMessageText: 'Hello',
              lastMessageAt: DateTime.now(),
              unreadCounts: {'user1': 2},
            ),
          ]),
        );
      },
      build: () => conversationsBloc,
      act: (bloc) => bloc.add(ConversationsStarted(userId: 'user1')),
      expect: () => [
        isA<ConversationsLoading>(),
        isA<ConversationsLoaded>()
            .having((state) => state.conversations, 'conversations', isNotEmpty)
            .having(
              (state) => state.conversations.first.otherUserDisplayName,
              'otherUserDisplayName',
              'John Doe',
            ),
      ],
    );

    blocTest<ConversationsBloc, ConversationsState>(
      'emits ConversationsLoading then ConversationsError when stream errors',
      setUp: () {
        when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
          (_) => Stream.error(Exception('Network error')),
        );
      },
      build: () => conversationsBloc,
      act: (bloc) => bloc.add(ConversationsStarted(userId: 'user1')),
      expect: () => [
        isA<ConversationsLoading>(),
        isA<ConversationsError>(),
      ],
    );

    blocTest<ConversationsBloc, ConversationsState>(
      'emits ConversationsLoaded with empty list when no conversations',
      setUp: () {
        when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
          (_) => Stream.value([]),
        );
      },
      build: () => conversationsBloc,
      act: (bloc) => bloc.add(ConversationsStarted(userId: 'user1')),
      expect: () => [
        isA<ConversationsLoading>(),
        isA<ConversationsLoaded>()
            .having((state) => state.conversations, 'conversations', isEmpty),
      ],
    );
  });
}
