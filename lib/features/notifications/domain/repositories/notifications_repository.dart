// lib/features/notifications/domain/repositories/notifications_repository.dart
//
// NotificationsRepository — abstract repository contract.

import '../entities/notification_item.dart';

/// Contract for the notifications data source.
abstract class NotificationsRepository {
  /// Stream of up to 50 most-recent notifications for [userId], newest first.
  Stream<List<NotificationItem>> watchNotifications({required String userId});

  /// Stream of the unread notification count for [userId].
  Stream<int> watchUnreadCount({required String userId});

  /// Marks a single notification as read.
  Future<void> markAsRead({required String notificationId});

  /// Stream of the actor's current profile picture URL from `users/{actorId}`.
  ///
  /// Emits `null` when the actor has no photo.
  Stream<String?> watchActorPhotoUrl({required String actorId});
}
