import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/edit_profile_screen.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  late MockProfileBloc mockProfileBloc;

  setUp(() {
    mockProfileBloc = MockProfileBloc();
  });

  final testProfile = UserProfile(
    uid: 'test-uid',
    displayName: 'Test User',
    bio: 'Test bio',
    avatarUrl: 'https://example.com/avatar.jpg',
    postCount: 3,
  );

  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<ProfileBloc>.value(
        value: mockProfileBloc,
        child: const EditProfileScreen(),
      ),
    );
  }

  group('EditProfileScreen', () {
    testWidgets('displayName field is pre-filled with profile displayName',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Verify displayName is in one of the text fields
      expect(find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == 'Test User',
      ), findsWidgets);
    });

    testWidgets('bio field is pre-filled with profile bio',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileLoaded(profile: testProfile)]),
        initialState: ProfileLoaded(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == 'Test bio',
      ), findsWidgets);
    });

    testWidgets('displays CircularProgressIndicator when ProfileUpdating',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileUpdating(profile: testProfile)]),
        initialState: ProfileUpdating(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays CircularProgressIndicator when ProfileUpdating',
        (WidgetTester tester) async {
      whenListen(
        mockProfileBloc,
        Stream.fromIterable([ProfileUpdating(profile: testProfile)]),
        initialState: ProfileUpdating(profile: testProfile),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
