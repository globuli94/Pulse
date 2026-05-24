import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/edit_profile_screen.dart';

class MockProfileBloc extends Mock implements ProfileBloc {}

void main() {
  group('EditProfileScreen', () {
    late MockProfileBloc mockProfileBloc;

    setUp(() {
      mockProfileBloc = MockProfileBloc();
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: BlocProvider<ProfileBloc>.value(
          value: mockProfileBloc,
          child: const EditProfileScreen(),
        ),
      );
    }

    testWidgets('AC-2: displays display name text field',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('AC-2: displays bio text field', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('AC-2: displays Save button', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(
        find.text('Save'),
        findsOneWidget,
      );
    });

    testWidgets('AC-2: displays loading state while updating',
        (WidgetTester tester) async {
      when(() => mockProfileBloc.state).thenReturn(const ProfileUpdating());
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileUpdating()),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump(); // Single frame to render

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AC-2: displays updated profile after successful update',
        (WidgetTester tester) async {
      final updatedProfile = UserProfile(
        uid: 'test-uid',
        displayName: 'Updated Name',
        username: 'testuser',
        bio: 'Updated bio',
        avatarUrl: '',
        followerCount: 10,
        followingCount: 5,
        postCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 3),
      );

      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: updatedProfile));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileLoaded(profile: updatedProfile)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Updated Name'), findsOneWidget);
      expect(find.text('Updated bio'), findsOneWidget);
    });

    testWidgets('AC-2: does not allow empty display name',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Find and fill the display name field with empty value
      final displayNameFields = find.byType(TextFormField);
      await tester.enterText(displayNameFields.first, '');

      // Try to save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Expect error or validation message
      expect(
        find.text('Display name cannot be empty'),
        findsOneWidget,
      );
    });

    testWidgets('AC-8: displays error message when update fails',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to update profile';
      when(() => mockProfileBloc.state)
          .thenReturn(const ProfileFailure(message: errorMessage));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileFailure(message: errorMessage)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
    });
  });
}
