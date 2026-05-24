import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:pulse/features/auth/presentation/widgets/auth_header.dart';

class MockForgotPasswordBloc extends Mock implements ForgotPasswordBloc {}

void main() {
  group('ForgotPasswordScreen', () {
    late MockForgotPasswordBloc mockForgotPasswordBloc;

    setUp(() {
      mockForgotPasswordBloc = MockForgotPasswordBloc();
      when(() => mockForgotPasswordBloc.state)
          .thenReturn(const ForgotPasswordInitial());
      when(() => mockForgotPasswordBloc.stream)
          .thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: BlocProvider<ForgotPasswordBloc>.value(
          value: mockForgotPasswordBloc,
          child: const ForgotPasswordScreen(),
        ),
      );
    }

    testWidgets('renders AuthHeader', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byType(AuthHeader), findsOneWidget);
    });

    testWidgets('renders email field', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('renders Send Reset Email button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Send Reset Email'), findsOneWidget);
    });

    testWidgets('displays success message when ForgotPasswordBloc emits success state',
        (WidgetTester tester) async {
      when(() => mockForgotPasswordBloc.state)
          .thenReturn(const ForgotPasswordSuccess());
      when(() => mockForgotPasswordBloc.stream).thenAnswer(
        (_) => Stream.value(const ForgotPasswordSuccess()),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Check your inbox'), findsOneWidget);
    });

    testWidgets('displays error message when ForgotPasswordBloc emits error state',
        (WidgetTester tester) async {
      const errorMessage = 'No account found for this email.';
      when(() => mockForgotPasswordBloc.state)
          .thenReturn(const ForgotPasswordFailure(message: errorMessage));
      when(() => mockForgotPasswordBloc.stream).thenAnswer(
        (_) => Stream.value(const ForgotPasswordFailure(message: errorMessage)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
