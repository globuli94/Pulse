import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/profile/presentation/widgets/profile_avatar_widget.dart';

void main() {
  group('ProfileAvatarWidget', () {
    testWidgets('AC-3: renders CircleAvatar widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatarWidget(
              avatarUrl: 'https://example.com/avatar.jpg',
              onCameraPressed: () {},
            ),
          ),
        ),
      );

      // Widget builds without crashing - network image load failures are handled
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('AC-3: displays fallback Icons.person when avatarUrl is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatarWidget(
              avatarUrl: '',
              onCameraPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('AC-3: displays camera button overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatarWidget(
              avatarUrl: '',
              onCameraPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('AC-3: calls onCameraPressed when camera button is tapped',
        (WidgetTester tester) async {
      bool cameraPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatarWidget(
              avatarUrl: '',
              onCameraPressed: () {
                cameraPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pump();

      expect(cameraPressed, true);
    });

    testWidgets('AC-3: handles null avatarUrl gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAvatarWidget(
              avatarUrl: null,
              onCameraPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
