import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/user_profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/user_profile_view_screen.dart';

class MockUserProfileBloc extends MockBloc<UserProfileEvent, UserProfileState>
    implements UserProfileBloc {}

void main() {
  late MockUserProfileBloc mockUserProfileBloc;

  setUp(() {
    mockUserProfileBloc = MockUserProfileBloc();
  });

  final testProfile = UserProfile(
    uid: 'other-uid',
    displayName: 'Other User',
    bio: 'Other user bio',
    avatarUrl: 'https://example.com/other-avatar.jpg',
    postCount: 5,
  );

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<UserProfileBloc>.value(
        value: mockUserProfileBloc,
        child: const UserProfileViewScreen(),
      ),
    );
  }

  group('UserProfileViewScreen', () {
    testWidgets('displays CircularProgressIndicator when loading',
        (WidgetTester tester) async {
      whenListen(
        mockUserProfileBloc,
        Stream.fromIterable([UserProfileLoading()]),
        initialState: UserProfileLoading(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays displayName when loaded', (WidgetTester tester) async {
      whenListen(
        mockUserProfileBloc,
        Stream.fromIterable([UserProfileLoaded(testProfile)]),
        initialState: UserProfileLoaded(testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Other User'), findsWidgets);
    });

    testWidgets('does not show Edit Profile button',
        (WidgetTester tester) async {
      whenListen(
        mockUserProfileBloc,
        Stream.fromIterable([UserProfileLoaded(testProfile)]),
        initialState: UserProfileLoaded(testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsNothing);
    });

    testWidgets('does not show Logout button', (WidgetTester tester) async {
      whenListen(
        mockUserProfileBloc,
        Stream.fromIterable([UserProfileLoaded(testProfile)]),
        initialState: UserProfileLoaded(testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsNothing);
    });

    testWidgets('does not show Delete Account button',
        (WidgetTester tester) async {
      whenListen(
        mockUserProfileBloc,
        Stream.fromIterable([UserProfileLoaded(testProfile)]),
        initialState: UserProfileLoaded(testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsNothing);
    });

    testWidgets('displays error message on UserProfileError',
        (WidgetTester tester) async {
      whenListen(
        mockUserProfileBloc,
        Stream.fromIterable([UserProfileError('User not found')]),
        initialState: UserProfileError('User not found'),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('User not found'), findsWidgets);
    });
  });
}
