// test/features/profile/presentation/widgets/follow_user_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/widgets/follow_user_tile.dart';

void main() {
  final testProfile = UserProfile(
    uid: 'user-123',
    displayName: 'Jane Doe',
    bio: 'Test bio',
    avatarUrl: null,
    postCount: 5,
    followerCount: 10,
    followingCount: 3,
  );

  Widget buildSubject(UserProfile profile) {
    final router = GoRouter(
      initialLocation: '/test',
      routes: [
        GoRoute(
          path: '/test',
          builder: (context, state) => Scaffold(
            body: FollowUserTile(profile: profile),
          ),
        ),
        GoRoute(
          path: '/profile/:uid',
          builder: (context, state) => Scaffold(
            body: Text('Profile ${state.pathParameters['uid']}'),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('FollowUserTile', () {
    testWidgets('renders display name', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject(testProfile));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('renders a ListTile', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject(testProfile));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('navigates to /profile/:uid on tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildSubject(testProfile));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.text('Profile user-123'), findsOneWidget);
    });
  });
}
