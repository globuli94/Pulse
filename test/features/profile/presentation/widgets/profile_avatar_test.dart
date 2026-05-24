import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/profile/presentation/widgets/profile_avatar.dart';

void main() {
  group('ProfileAvatar', () {
    testWidgets('displays placeholder icon when avatarUrl is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(avatarUrl: null, radius: 40),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsWidgets);
    });

    testWidgets('renders without error when avatarUrl is set',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileAvatar(
              avatarUrl: 'https://example.com/avatar.jpg',
              radius: 40,
            ),
          ),
        ),
      );

      // Widget should render without throwing
      expect(find.byType(ProfileAvatar), findsOneWidget);
      // Network image may fail in tests, but widget should still be present
      await tester.pump();
    });
  });
}
