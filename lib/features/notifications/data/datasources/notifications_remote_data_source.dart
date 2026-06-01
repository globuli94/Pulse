// lib/features/notifications/data/datasources/notifications_remote_data_source.dart
//
// NotificationsRemoteDataSource — abstract data source contract.

/// Abstract contract for the notifications remote data source.
abstract class NotificationsRemoteDataSource {
  /// Stream of raw notification maps for [userId], newest first, limit 50.
  Stream<List<Map<String, dynamic>>> watchNotifications(
      {required String userId});

  /// Stream of unread notification count for [userId].
  Stream<int> watchUnreadCount({required String userId});

  /// Marks a single notification document as read.
  Future<void> markAsRead({required String notificationId});

  /// Stream of the actor's current `avatarUrl` from `users/{actorId}`.
  ///
  /// Emits `null` when the user document does not have an `avatarUrl`.
  Stream<String?> watchActorPhotoUrl({required String actorId});
}
