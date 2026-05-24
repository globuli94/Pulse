// lib/core/router/go_router_refresh_stream.dart
//
// GoRouterRefreshStream — bridges a Dart stream to a ChangeNotifier for go_router.

import 'dart:async';

import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that notifies listeners whenever a [Stream] emits.
///
/// Pass this to [GoRouter.refreshListenable] to trigger a route re-evaluation
/// whenever the stream produces a new value (e.g., on auth state change).
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream] that listens to [stream].
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
