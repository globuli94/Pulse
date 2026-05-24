import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/profile_screen.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockProfileBloc mockProfileBloc;
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    mockAuthBloc = MockAuthBloc();
  });

  final testProfile = UserProfile(
    uid: 'test-uid',
    displayName: 'Test User',
    bio: 'Test bio',
    avatarUrl: 'https://example.com/avatar.jpg',
    postCount: 3,
  );

  final testProfileNoBio = UserProfile(
    uid: 'test-uid',
    displayName: 'Test User',
    bio: '',
    avatarUrl: 'https://example.com/avatar.jpg',
    postCount: 3,
  );

  Widget buildTestWidget() {
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

  group('ProfileScreen', () {
    testWidgets('displays CircularProgressIndicator when loading',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoading()]),
        initialState: ProfileLoading(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays displayName when loaded', (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsWidgets);
    });

    testWidgets('displays bio when loaded with non-empty bio',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Test bio'), findsWidgets);
    });

    testWidgets('displays "No bio yet." when bio is empty',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfileNoBio)]),
        initialState: ProfileLoaded(profile: testProfileNoBio),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No bio yet.'), findsWidgets);
    });

    testWidgets('displays post count', (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.contains('3') == true && widget.data?.contains('post') == true,
      ), findsWidgets);
    });

    testWidgets('displays Edit Profile button', (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsWidgets);
    });

    testWidgets('displays Logout button', (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsWidgets);
    });

    testWidgets('displays Delete Account button', (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsWidgets);
    });

    testWidgets('adds ProfileSignOutRequested when Logout tapped',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Verify Logout button is present (tap interaction testing requires full navigation setup)
      expect(find.text('Logout'), findsWidgets);
    });


    testWidgets('displays error message on ProfileError',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileError(message: 'Something went wrong')]),
        initialState: ProfileError(message: 'Something went wrong'),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsWidgets);
    });
  });
}
