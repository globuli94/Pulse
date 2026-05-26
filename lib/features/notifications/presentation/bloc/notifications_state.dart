// lib/features/notifications/presentation/bloc/notifications_state.dart
//
// NotificationsState — states for NotificationsBloc.

part of 'notifications_bloc.dart';

/// Base class for all notifications states.
abstract class NotificationsState {
  const NotificationsState();
}

/// Initial state before subscription is started.
class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// Loading state while waiting for the first stream event.
class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// Loaded state carrying the current list of notifications.
class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded({required this.notifications});

  final List<NotificationItem> notifications;
}

/// Error state with a message describing what went wrong.
class NotificationsError extends NotificationsState {
  const NotificationsError({required this.message});

  final String message;
}
