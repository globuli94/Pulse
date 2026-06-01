// lib/features/notifications/presentation/bloc/unread_notifications_count_cubit.dart
//
// UnreadNotificationsCountCubit — tracks the unread notification count
// globally for the current user.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/notifications_repository.dart';

/// Global cubit that emits the current unread notification count.
///
/// Provided in main.dart so the bell badge in the AppBar can observe it
/// from any tab.
class UnreadNotificationsCountCubit extends Cubit<int> {
  /// Creates an [UnreadNotificationsCountCubit].
  UnreadNotificationsCountCubit({
    required NotificationsRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(0);

  final NotificationsRepository _repository;
  String _userId;
  StreamSubscription<int>? _subscription;

  /// Starts (or restarts) the Firestore stream subscription for [userId].
  ///
  /// Cancels any previous subscription first so the cubit is safe to call
  /// again when the authenticated user changes.
  void startWatching(String userId) {
    _subscription?.cancel();
    _userId = userId;
    watchUnreadCount();
  }

  /// Starts listening to the unread count stream.
  void watchUnreadCount() {
    if (_userId.isEmpty) return;
    _subscription = _repository
        .watchUnreadCount(userId: _userId)
        .listen(emit, onError: (_) => emit(0));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
