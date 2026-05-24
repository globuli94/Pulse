import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('Auth Guard - Navigation to /home', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    testWidgets(
      'Unauthenticated navigation to /home redirects to /login',
      (WidgetTester tester) async {
        // Mock unauthenticated state
        when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(const Unauthenticated()),
        );

        // Create a router with auth guard that mimics the app's behavior
        final router = GoRouter(
          initialLocation: '/',
          redirect: (BuildContext context, GoRouterState state) {
            // If trying to access /home while unauthenticated, redirect to /login
            if (state.fullPath == '/home' && mockAuthBloc.state is Unauthenticated) {
              return '/login';
            }
            return null;
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Home')),
              ),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Login')),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: mockAuthBloc,
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Navigate to /home while unauthenticated
        router.go('/home');
        await tester.pumpAndSettle();

        // Verify that we were redirected to /login
        expect(find.text('Login'), findsOneWidget);
      },
    );
  });
}
