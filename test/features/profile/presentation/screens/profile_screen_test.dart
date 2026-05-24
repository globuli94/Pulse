import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/profile_screen.dart';

class MockProfileBloc extends Mock implements ProfileBloc {}

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('ProfileScreen', () {
    late MockProfileBloc mockProfileBloc;
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockProfileBloc = MockProfileBloc();
      mockAuthBloc = MockAuthBloc();
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<ProfileBloc>.value(value: mockProfileBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          ],
          child: const ProfileScreen(),
        ),
      );
    }

    testWidgets('AC-1: renders loading state while fetching profile',
        (WidgetTester tester) async {
      when(() => mockProfileBloc.state).thenReturn(const ProfileLoading());
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileLoading()),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump(); // pump once — pumpAndSettle loops on CircularProgressIndicator

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AC-1: displays avatar, display name, username, bio, post count',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        username: 'testuser',
        bio: 'Test bio',
        avatarUrl: 'https://example.com/avatar.jpg',
        followerCount: 10,
        followingCount: 5,
        postCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: profile));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileLoaded(profile: profile)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@testuser'), findsOneWidget);
      expect(find.text('Test bio'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // postCount
      expect(find.text('Posts'), findsOneWidget); // label
    });

    testWidgets('AC-2: displays Edit Profile button when profile is loaded',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        username: 'testuser',
        bio: 'Test bio',
        avatarUrl: '',
        followerCount: 10,
        followingCount: 5,
        postCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: profile));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileLoaded(profile: profile)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('AC-3: displays camera icon for avatar upload',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        username: 'testuser',
        bio: 'Test bio',
        avatarUrl: '',
        followerCount: 10,
        followingCount: 5,
        postCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: profile));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileLoaded(profile: profile)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('AC-5: displays Log Out button', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        username: 'testuser',
        bio: 'Test bio',
        avatarUrl: '',
        followerCount: 10,
        followingCount: 5,
        postCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: profile));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileLoaded(profile: profile)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('AC-6: displays Delete Account button', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'test-uid',
        displayName: 'Test User',
        username: 'testuser',
        bio: 'Test bio',
        avatarUrl: '',
        followerCount: 10,
        followingCount: 5,
        postCount: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: profile));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(ProfileLoaded(profile: profile)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('AC-8: displays error message when profile load fails',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to load profile';
      when(() => mockProfileBloc.state)
          .thenReturn(const ProfileFailure(message: errorMessage));
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileFailure(message: errorMessage)),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump(); // pump once — error text is synchronously rendered

      // Error text appears in Scaffold body; listener also shows it in a SnackBar.
      expect(find.text(errorMessage), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Scaffold without error', (WidgetTester tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
