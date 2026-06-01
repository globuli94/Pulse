// Copyright 2024 Social Media Company. All rights reserved.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/chat/domain/entities/conversation.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/chat/presentation/screens/conversations_screen.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  group('ConversationsScreen', () {
    late MockAuthBloc mockAuthBloc;
    late MockChatRepository mockChatRepository;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockChatRepository = MockChatRepository();

      // Mock authenticated user
      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));

      // Mock ChatRepository to stream conversations
      final testConversations = [
        Conversation(
          id: 'conv-1',
          participantIds: ['test-uid', 'other-uid'],
          otherUserDisplayName: 'Other User',
          otherUserAvatarUrl: null,
          lastMessageText: 'Hello',
          lastMessageAt: DateTime.now(),
          unreadCounts: {'test-uid': 0, 'other-uid': 0},
        ),
      ];
      when(() => mockChatRepository.watchConversations(any()))
          .thenAnswer((_) => Stream.value(testConversations));
    });

    testWidgets(
      'SOCAA-564: ListView.separated has correct top padding (status bar + toolbar)',
      (WidgetTester tester) async {

        await tester.pumpWidget(
          RepositoryProvider<ChatRepository>.value(
            value: mockChatRepository,
            child: BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const MaterialApp(home: ConversationsScreen()),
            ),
          ),
        );

        // Wait for bloc to emit loaded state
        await tester.pumpAndSettle();

        // Find the ListView.separated
        final listViewFinder = find.byType(ListView);
        expect(listViewFinder, findsOneWidget);

        // Get the ListView widget
        final listView = tester.widget<ListView>(listViewFinder);

        // Get MediaQuery padding from the context
        final context = tester.element(listViewFinder);
        final mediaQueryPadding = MediaQuery.of(context).padding.top;
        final expectedTop = mediaQueryPadding + kToolbarHeight;

        // Assert padding.top
        final resolvedPadding = listView.padding?.resolve(TextDirection.ltr);
        expect(resolvedPadding?.top, expectedTop);
      },
    );
  });
}
