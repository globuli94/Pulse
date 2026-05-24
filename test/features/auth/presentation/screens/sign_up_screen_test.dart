import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/sign_up_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:pulse/features/auth/presentation/widgets/auth_header.dart';

class MockSignUpBloc extends Mock implements SignUpBloc {}

void main() {
  group('SignUpScreen', () {
    late MockSignUpBloc mockSignUpBloc;

    setUp(() {
      mockSignUpBloc = MockSignUpBloc();
      when(() => mockSignUpBloc.state).thenReturn(const SignUpInitial());
      when(() => mockSignUpBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: BlocProvider<SignUpBloc>.value(
          value: mockSignUpBloc,
          child: const SignUpScreen(),
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

    testWidgets('renders password field', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byIcon(Icons.lock_outlined), findsWidgets);
    });

    testWidgets('renders confirm password field', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(
        find.byType(TextFormField),
        findsNWidgets(3), // email, password, confirm password
      );
    });

    testWidgets('renders Create Account button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('displays validation message when passwords do not match',
        (WidgetTester tester) async {
      const validationMessage = 'Passwords do not match.';
      when(() => mockSignUpBloc.state)
          .thenReturn(const SignUpFailure(message: validationMessage));
      when(() => mockSignUpBloc.stream).thenAnswer(
        (_) => Stream.value(const SignUpFailure(message: validationMessage)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(validationMessage), findsOneWidget);
    });

    testWidgets('displays error message when SignUpBloc emits error state',
        (WidgetTester tester) async {
      const errorMessage = 'An account already exists for this email.';
      when(() => mockSignUpBloc.state)
          .thenReturn(const SignUpFailure(message: errorMessage));
      when(() => mockSignUpBloc.stream).thenAnswer(
        (_) => Stream.value(const SignUpFailure(message: errorMessage)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
