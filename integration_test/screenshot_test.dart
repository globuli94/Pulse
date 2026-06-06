// integration_test/screenshot_test.dart
//
// Navigates to Feed, Messages, Profile, Notifications, and Comments screens.
// Screenshot bytes are sent back to the driver via reportData.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pulse/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture all 6 screenshots', (tester) async {
    app.main();

    // Pump real time to let Firebase auth + initial data load settle.
    // Using pump(duration) advances the clock without waiting for quiescence,
    // which avoids infinite-wait when Firebase streams keep firing updates.
    await tester.pump(const Duration(seconds: 8));

    final Map<String, dynamic> screenshots = {};

    Future<void> capture(String name) async {
      // Let pending frames drain, then advance clock for any in-flight loads.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 3));
      final bytes = await binding.takeScreenshot(name);
      screenshots[name] = base64Encode(bytes);
    }

    // Helper: tap a bottom nav tab by its label text
    Future<void> tapBottomNavTab(String label) async {
      await tester.tap(find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text(label),
      ));
      await tester.pump(); // register the tap
    }

    // ── Feed (default screen after login) ─────────────────────────────────
    await capture('feed');

    // ── Comment Feed (feed showing comment count button inline with like) ──
    await capture('comment_feed');

    // ── Messages ──────────────────────────────────────────────────────────
    await tapBottomNavTab('Messages');
    await capture('messages');

    // ── Profile ───────────────────────────────────────────────────────────
    await tapBottomNavTab('Profile');
    await capture('profile');

    // ── Notifications (bell icon in AppBar — pushes /notifications route) ─
    await tester.tap(find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.notifications_outlined),
    ));
    await tester.pump(); // register tap
    // Extra pump to complete the push animation (300ms default) then data load
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 4));
    final notifBytes = await binding.takeScreenshot('notifications');
    screenshots['notifications'] = base64Encode(notifBytes);

    // ── Back to Feed for comment screen capture ───────────────────────────
    // Pop the notifications route to return to the shell
    final NavigatorState navigator =
        tester.state(find.byType(Navigator).last);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Navigate to Feed tab
    await tapBottomNavTab('Feed');
    await tester.pump(const Duration(seconds: 2));

    // ── Comments Screen ───────────────────────────────────────────────────
    // Tap the comment button (chat bubble) on the first visible post
    await tester.tap(find.byIcon(Icons.chat_bubble_outline).first);
    await tester.pump(); // register tap
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 4));
    final commentBytes = await binding.takeScreenshot('comment_screen');
    screenshots['comment_screen'] = base64Encode(commentBytes);

    binding.reportData = screenshots;
  });
}
