import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/main.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('app boots without assertion errors', (tester) async {
    final mockAuthBloc = MockAuthBloc();
    final mockAuthRepository = MockAuthRepository();

    // Mock authenticated state
    final testUser = AppUser(
      uid: 'test-uid',
      email: 'test@example.com',
      displayName: 'Test User',
    );

    when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => const Stream.empty(),
    );

    // Create a simple router for testing
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const SizedBox(),
        ),
      ],
    );

    await tester.pumpWidget(
      PulseApp(
        authBloc: mockAuthBloc,
        authRepository: mockAuthRepository,
        router: router,
      ),
    );
    await tester.pump();
  });
}
