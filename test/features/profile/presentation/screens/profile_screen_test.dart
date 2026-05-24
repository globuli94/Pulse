import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/profile/presentation/screens/profile_screen.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('renders Scaffold without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      // Verify ProfileScreen renders without error
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Verify Scaffold is rendered
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
