// lib/features/notifications/presentation/bloc/notifications_bloc.dart
//
// NotificationsBloc — manages the notifications list for a single screen.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Screen-scoped BLoC that manages the notifications list.
///
/// Provided in the router builder for `/notifications` — not in main.dart.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  /// Creates a [NotificationsBloc].
  NotificationsBloc({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsInitial()) {
    on<NotificationsSubscriptionRequested>(_onSubscriptionRequested);
    on<NotificationMarkReadRequested>(_onMarkReadRequested);
  }

  final NotificationsRepository _repository;

  Future<void> _onSubscriptionRequested(
    NotificationsSubscriptionRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    await emit.forEach<List<NotificationItem>>(
      _repository.watchNotifications(userId: event.userId),
      onData: (list) => NotificationsLoaded(notifications: list),
      onError: (e, _) => NotificationsError(message: e.toString()),
    );
  }

  Future<void> _onMarkReadRequested(
    NotificationMarkReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    await _repository.markAsRead(notificationId: event.notificationId);
    // No state change needed — the stream will update automatically.
  }
}
