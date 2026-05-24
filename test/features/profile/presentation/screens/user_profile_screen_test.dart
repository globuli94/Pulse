import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/user_profile_screen.dart';

class MockProfileBloc extends Mock implements ProfileBloc {}

void main() {
  group('UserProfileScreen', () {
    late MockProfileBloc mockProfileBloc;

    setUp(() {
      mockProfileBloc = MockProfileBloc();
      when(() => mockProfileBloc.state).thenReturn(const ProfileInitial());
      when(() => mockProfileBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget buildScreen({String uid = 'other-uid'}) {
      return MaterialApp(
        home: BlocProvider<ProfileBloc>.value(
          value: mockProfileBloc,
          child: UserProfileScreen(uid: uid),
        ),
      );
    }

    testWidgets('AC-4: displays user avatar', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: 'https://example.com/other-avatar.jpg',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('AC-4: displays display name', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: '',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.text('Other User'), findsOneWidget);
    });

    testWidgets('AC-4: displays username', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: '',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.text('@otheruser'), findsOneWidget);
    });

    testWidgets('AC-4: displays bio', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: '',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.text('Other user bio'), findsOneWidget);
    });

    testWidgets('AC-4: displays post count', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: '',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.text('10'), findsOneWidget); // postCount
      expect(find.text('Posts'), findsOneWidget); // label
    });

    testWidgets('AC-4: does NOT show Edit Profile button',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: '',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.text('Edit Profile'), findsNothing);
    });

    testWidgets('AC-4: does NOT show Log Out button', (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: '',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.text('Log Out'), findsNothing);
    });

    testWidgets('AC-4: does NOT show Delete Account button',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Other User',
        username: 'otheruser',
        bio: 'Other user bio',
        avatarUrl: '',
        followerCount: 5,
        followingCount: 2,
        postCount: 10,
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

      expect(find.text('Delete Account'), findsNothing);
    });

    testWidgets('AC-4: displays loading state while fetching profile',
        (WidgetTester tester) async {
      when(() => mockProfileBloc.state).thenReturn(const ProfileLoading());
      when(() => mockProfileBloc.stream).thenAnswer(
        (_) => Stream.value(const ProfileLoading()),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
