import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/chat/domain/entities/conversation.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/screens/conversations_screen.dart';

class MockChatRepository extends Mock implements ChatRepository {}


class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockChatRepository mockChatRepository;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockAuthBloc = MockAuthBloc();
    whenListen(
      mockAuthBloc,
      Stream<AuthState>.empty(),
      initialState: const Unauthenticated(),
    );
  });

  Widget createWidgetUnderTest({required AuthState authState}) {
    when(() => mockAuthBloc.state).thenReturn(authState);

    return MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ChatRepository>(create: (_) => mockChatRepository),
        ],
        child: BlocProvider<AuthBloc>(
          create: (_) => mockAuthBloc,
          child: const ConversationsScreen(),
        ),
      ),
    );
  }

  group('ConversationsScreen', () {
    testWidgets('shows CircularProgressIndicator on ConversationsLoading',
        (WidgetTester tester) async {
      when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
        (_) => const Stream.empty(),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: Authenticated(
            AppUser(
              uid: 'user1',
              email: 'user@example.com',
              displayName: 'Test User',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows "No conversations yet" on empty list',
        (WidgetTester tester) async {
      when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: Authenticated(
            AppUser(
              uid: 'user1',
              email: 'user@example.com',
              displayName: 'Test User',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No conversations yet.'), findsWidgets);
    });

    testWidgets('shows conversation tile with otherUserDisplayName',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: Authenticated(
            AppUser(
              uid: 'user1',
              email: 'user@example.com',
              displayName: 'Test User',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('John Doe'), findsWidgets);
    });

    testWidgets('shows unread badge when unreadCounts > 0',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: Authenticated(
            AppUser(
              uid: 'user1',
              email: 'user@example.com',
              displayName: 'Test User',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2'), findsWidgets);
    });

    testWidgets('shows "Messages" in AppBar', (WidgetTester tester) async {
      when(() => mockChatRepository.watchConversations('user1')).thenAnswer(
        (_) => Stream.value([]),
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          authState: Authenticated(
            AppUser(
              uid: 'user1',
              email: 'user@example.com',
              displayName: 'Test User',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsWidgets);
    });
  });
}
