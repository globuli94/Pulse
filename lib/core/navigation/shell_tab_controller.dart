// lib/core/navigation/shell_tab_controller.dart
//
// ShellTabController — allows widgets outside ShellScreen to request a
// tab switch without full route navigation.

import 'package:flutter/foundation.dart';

/// Notifier that controls which tab is active in [ShellScreen].
///
/// Provided globally via [RepositoryProvider] in `main.dart`.
/// Write a tab index to switch tabs from anywhere in the widget tree.
///
/// Tab indices:
///   0 — Feed
///   1 — Search
///   2 — Messages
///   3 — Profile
class ShellTabController extends ValueNotifier<int> {
  /// Creates a [ShellTabController] starting on the Feed tab (index 0).
  ShellTabController() : super(0);
}
