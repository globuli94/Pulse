import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/login_bloc.dart';
import 'package:pulse/features/auth/presentation/screens/login_screen.dart';
import 'package:pulse/features/auth/presentation/widgets/auth_header.dart';

class MockLoginBloc extends Mock implements LoginBloc {}

void main() {
  group('LoginScreen', () {
    late MockLoginBloc mockLoginBloc;

    setUp(() {
      mockLoginBloc = MockLoginBloc();
      when(() => mockLoginBloc.state).thenReturn(const LoginInitial());
      when(() => mockLoginBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: BlocProvider<LoginBloc>.value(
          value: mockLoginBloc,
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('renders AuthHeader widget', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byType(AuthHeader), findsOneWidget);
    });

    testWidgets('renders email field', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('renders password field', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('renders Log In button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('renders Sign in with Google button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('renders Forgot password? link', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('renders sign-up link', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Sign up'), findsOneWidget);
    });

    testWidgets('displays error message when LoginBloc emits error state',
        (WidgetTester tester) async {
      const errorMessage = 'Incorrect password.';
      when(() => mockLoginBloc.state)
          .thenReturn(const LoginFailure(message: errorMessage));
      when(() => mockLoginBloc.stream).thenAnswer(
        (_) => Stream.value(const LoginFailure(message: errorMessage)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
