import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/bloc/chat_bloc.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late ChatBloc chatBloc;
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    chatBloc = ChatBloc(
      repository: mockChatRepository,
    );
  });

  tearDown(() {
    chatBloc.close();
  });

  group('ChatBloc', () {
    test('initial state is ChatInitial', () {
      expect(chatBloc.state, isA<ChatInitial>());
    });

    blocTest<ChatBloc, ChatState>(
      'emits ChatLoading then ChatLoaded when ChatStarted is added and calls markAsRead',
      setUp: () {
        when(
          () => mockChatRepository.markAsRead(
            conversationId: 'conv1',
            userId: 'user1',
          ),
        ).thenAnswer((_) async {});

        when(() => mockChatRepository.watchMessages('conv1')).thenAnswer(
          (_) => Stream.value([
            Message(
              id: 'msg1',
              senderId: 'user2',
              text: 'Hello',
              createdAt: DateTime.now(),
            ),
          ]),
        );
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(
        ChatStarted(
          conversationId: 'conv1',
          currentUserId: 'user1',
          otherUserId: 'user2',
        ),
      ),
      verify: (_) {
        verify(
          () => mockChatRepository.markAsRead(
            conversationId: 'conv1',
            userId: 'user1',
          ),
        ).called(1);
      },
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatLoaded>()
            .having((state) => state.messages, 'messages', isNotEmpty),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits ChatLoading then ChatError when stream errors',
      setUp: () {
        when(
          () => mockChatRepository.markAsRead(
            conversationId: 'conv1',
            userId: 'user1',
          ),
        ).thenAnswer((_) async {});

        when(() => mockChatRepository.watchMessages('conv1')).thenAnswer(
          (_) => Stream.error(Exception('Network error')),
        );
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(
        ChatStarted(
          conversationId: 'conv1',
          currentUserId: 'user1',
          otherUserId: 'user2',
        ),
      ),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatError>(),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits no state change when MessageSent succeeds',
      setUp: () {
        when(
          () => mockChatRepository.markAsRead(
            conversationId: 'conv1',
            userId: 'user1',
          ),
        ).thenAnswer((_) async {});

        when(() => mockChatRepository.watchMessages('conv1')).thenAnswer(
          (_) => Stream.value([]),
        );

        when(
          () => mockChatRepository.sendMessage(
            conversationId: 'conv1',
            senderId: 'user1',
            otherUserId: 'user2',
            text: 'Hi',
          ),
        ).thenAnswer((_) async {});
      },
      build: () => chatBloc,
      seed: () => ChatLoaded(messages: []),
      act: (bloc) {
        bloc.add(
          ChatStarted(
            conversationId: 'conv1',
            currentUserId: 'user1',
            otherUserId: 'user2',
          ),
        );
        bloc.add(
          MessageSent(
            conversationId: 'conv1',
            senderId: 'user1',
            otherUserId: 'user2',
            text: 'Hi',
          ),
        );
      },
      skip: 2, // Skip ChatLoading and ChatLoaded states from ChatStarted
      expect: () => [],
    );

    blocTest<ChatBloc, ChatState>(
      'emits ChatError when MessageSent fails',
      setUp: () {
        when(
          () => mockChatRepository.sendMessage(
            conversationId: any(named: 'conversationId'),
            senderId: any(named: 'senderId'),
            otherUserId: any(named: 'otherUserId'),
            text: any(named: 'text'),
          ),
        ).thenThrow(Exception('Send failed'));
      },
      build: () => chatBloc,
      act: (bloc) => bloc.add(
        MessageSent(
          conversationId: 'conv1',
          senderId: 'user1',
          otherUserId: 'user2',
          text: 'Hi',
        ),
      ),
      expect: () => [isA<ChatError>()],
    );
  });
}
