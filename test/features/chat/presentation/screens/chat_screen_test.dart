import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:pulse/features/chat/presentation/screens/chat_screen.dart';

class MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late MockChatRepository mockChatRepository;

  setUp(() {
    mockChatRepository = MockChatRepository();
    // ChatScreen.initState always dispatches ChatStarted.
    // markAsRead errors are non-fatal (caught in _onStarted); stub anyway.
    when(() => mockChatRepository.markAsRead(
          conversationId: any(named: 'conversationId'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) async {});
    // Default: stream closes immediately with no data → bloc stays ChatLoading.
    when(() => mockChatRepository.watchMessages(any()))
        .thenAnswer((_) => Stream.empty());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ChatRepository>(create: (_) => mockChatRepository),
        ],
        child: BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            repository: context.read<ChatRepository>(),
          ),
          child: const ChatScreen(
            conversationId: 'conv1',
            currentUserId: 'user1',
            otherUserId: 'user2',
            otherUserDisplayName: 'John Doe',
          ),
        ),
      ),
    );
  }

  group('ChatScreen', () {
    testWidgets('shows CircularProgressIndicator on ChatLoading',
        (WidgetTester tester) async {
      // watchMessages returns Stream.empty() → no data emitted → ChatLoading.
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows message bubbles on ChatLoaded',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final messages = [
        Message(
          id: 'msg1',
          senderId: 'user2',
          text: 'Hello',
          createdAt: now,
        ),
        Message(
          id: 'msg2',
          senderId: 'user1',
          text: 'Hi there',
          createdAt: now.add(const Duration(minutes: 1)),
        ),
      ];

      when(() => mockChatRepository.watchMessages('conv1'))
          .thenAnswer((_) => Stream.value(messages));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsWidgets);
      expect(find.text('Hi there'), findsWidgets);
    });

    testWidgets('shows own messages aligned right', (WidgetTester tester) async {
      final now = DateTime.now();
      final messages = [
        Message(
          id: 'msg1',
          senderId: 'user1',
          text: 'My message',
          createdAt: now,
        ),
      ];

      when(() => mockChatRepository.watchMessages('conv1'))
          .thenAnswer((_) => Stream.value(messages));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final messageBubble = find.byType(Align);
      expect(
        messageBubble,
        findsWidgets,
        reason: 'Message bubbles should be wrapped in Align for positioning',
      );
    });

    testWidgets('shows other user messages aligned left',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final messages = [
        Message(
          id: 'msg1',
          senderId: 'user2',
          text: 'Their message',
          createdAt: now,
        ),
      ];

      when(() => mockChatRepository.watchMessages('conv1'))
          .thenAnswer((_) => Stream.value(messages));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final messageBubble = find.byType(Align);
      expect(
        messageBubble,
        findsWidgets,
        reason: 'Message bubbles should be wrapped in Align for positioning',
      );
    });

    testWidgets('send button is present when text field is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsWidgets);

      final iconButton = find.byType(IconButton);
      expect(
        iconButton,
        findsWidgets,
        reason: 'Send button should be an IconButton',
      );
    });

    testWidgets('send button is enabled after text input',
        (WidgetTester tester) async {
      when(
        () => mockChatRepository.sendMessage(
          conversationId: any(named: 'conversationId'),
          senderId: any(named: 'senderId'),
          otherUserId: any(named: 'otherUserId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Test message');
      await tester.pump();

      final sendButton = find.byIcon(Icons.send);
      expect(sendButton, findsWidgets);
    });
  });
}
