import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/home/presentation/screens/home_screen.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('HomeScreen', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const HomeScreen(),
        ),
      );
    }

    testWidgets('renders Welcome to Pulse text', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.text('Welcome to Pulse'), findsOneWidget);
    });

    testWidgets('renders logout button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('logout button has correct tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byTooltip('Log out'), findsOneWidget);
    });
  });
}
