import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/feed/presentation/screens/feed_screen.dart';

void main() {
  group('FeedScreen', () {
    testWidgets('renders Scaffold without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeedScreen(),
        ),
      );

      // Verify FeedScreen renders without error
      expect(find.byType(FeedScreen), findsOneWidget);

      // Verify Scaffold is rendered
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
