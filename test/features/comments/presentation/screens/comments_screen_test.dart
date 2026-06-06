import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/comments/presentation/bloc/comments_bloc.dart';
import 'package:pulse/features/comments/presentation/screens/comments_screen.dart';

class MockCommentsBloc extends Mock implements CommentsBloc {}

void main() {
  group('CommentsScreen', () {
    late MockCommentsBloc mockCommentsBloc;

    setUp(() {
      mockCommentsBloc = MockCommentsBloc();
      when(() => mockCommentsBloc.state).thenReturn(const CommentsInitial());
      when(() => mockCommentsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: BlocProvider<CommentsBloc>.value(
          value: mockCommentsBloc,
          child: const CommentsScreen(
            postId: 'test-post-id',
            currentUserId: 'test-user-id',
          ),
        ),
      );
    }

    testWidgets(
      'SOCAA-783 #2: comment input field TextField has matching InputDecoration styling',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pump();

        // Find the TextField widget by its hint text
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsWidgets);

        // Get all TextField widgets and find the one with comment hint
        bool foundCommentInput = false;
        for (final element in textFieldFinder.evaluate()) {
          final textField = element.widget as TextField;
          if (textField.decoration?.hintText == 'Add a comment…') {
            final decoration = textField.decoration as InputDecoration;

            // Verify border styling matches _MessageInputBar
            expect(decoration.border, isA<OutlineInputBorder>());
            final outlineBorder = decoration.border as OutlineInputBorder;
            expect(outlineBorder.borderRadius, equals(const BorderRadius.all(Radius.circular(24))));

            // Verify content padding matches _MessageInputBar
            expect(
              decoration.contentPadding,
              equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            );

            // Verify hint text is set
            expect(decoration.hintText, isNotEmpty);
            foundCommentInput = true;
            break;
          }
        }

        expect(foundCommentInput, isTrue);
      },
    );

    testWidgets(
      'CommentsScreen displays comment input field and send button',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildScreen());
        await tester.pump();

        // Verify the input field is present
        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsWidgets);

        // Verify the hint text is visible
        expect(find.text('Add a comment…'), findsOneWidget);

        // Verify the send icon button is present
        final sendIconFinder = find.byIcon(Icons.send);
        expect(sendIconFinder, findsOneWidget);
      },
    );
  });
}
