// test/features/profile/presentation/screens/edit_profile_screen_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/edit_profile_screen.dart';

class MockProfileBloc extends Mock implements ProfileBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('EditProfileScreen', () {
    late MockProfileBloc mockProfileBloc;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockProfileBloc = MockProfileBloc();
      mockAuthBloc = MockAuthBloc();

      final testUser = AppUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      final testProfile = UserProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
      );
      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: testProfile));
      when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    testWidgets(
      'BUG-001e: shows camera/edit icon on avatar widget',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: const MaterialApp(home: EditProfileScreen()),
          ),
        );

        // Verify camera or edit icon is present on the avatar
        expect(
          find.byIcon(Icons.camera_alt),
          findsWidgets,
          reason: 'Camera icon should be present on avatar for editing',
        );
      },
    );

    testWidgets(
      'BUG-001e: EditProfileScreen builds without errors',
      (WidgetTester tester) async {
        final profile = UserProfile(
          uid: 'test-uid',
          displayName: 'Test User',
          bio: 'Test bio',
          avatarUrl: null,
          postCount: 0,
        );

        final initialState = ProfileLoaded(profile: profile);
        when(() => mockProfileBloc.state).thenReturn(initialState);
        when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            ],
            child: const MaterialApp(home: EditProfileScreen()),
          ),
        );

        // Verify that the screen rendered without errors
        // In production, this screen would support image selection and preview
        expect(find.byType(EditProfileScreen), findsOneWidget);
      },
    );
  });
}
