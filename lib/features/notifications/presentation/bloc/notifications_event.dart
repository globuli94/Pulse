// lib/features/notifications/presentation/bloc/notifications_event.dart
//
// NotificationsEvent — events for NotificationsBloc.

part of 'notifications_bloc.dart';

/// Base class for all notifications events.
abstract class NotificationsEvent {
  const NotificationsEvent();
}

/// Requests the notifications stream subscription for [userId].
class NotificationsSubscriptionRequested extends NotificationsEvent {
  /// Creates a [NotificationsSubscriptionRequested].
  const NotificationsSubscriptionRequested({required this.userId});

  final String userId;
}

/// Requests that a single notification is marked as read.
class NotificationMarkReadRequested extends NotificationsEvent {
  /// Creates a [NotificationMarkReadRequested].
  const NotificationMarkReadRequested({required this.notificationId});

  final String notificationId;
}
