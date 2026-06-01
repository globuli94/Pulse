// lib/features/notifications/data/repositories/notifications_repository_impl.dart
//
// NotificationsRepositoryImpl — data-layer implementation of
// NotificationsRepository.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

/// Concrete implementation of [NotificationsRepository] backed by Firestore.
class NotificationsRepositoryImpl implements NotificationsRepository {
  /// Creates a [NotificationsRepositoryImpl].
  NotificationsRepositoryImpl({required NotificationsRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final NotificationsRemoteDataSource _dataSource;

  @override
  Stream<List<NotificationItem>> watchNotifications({required String userId}) {
    return _dataSource.watchNotifications(userId: userId).map(
          (maps) => maps.map(_fromMap).toList(),
        );
  }

  @override
  Stream<int> watchUnreadCount({required String userId}) {
    return _dataSource.watchUnreadCount(userId: userId);
  }

  @override
  Future<void> markAsRead({required String notificationId}) {
    return _dataSource.markAsRead(notificationId: notificationId);
  }

  @override
  Stream<String?> watchActorPhotoUrl({required String actorId}) {
    return _dataSource.watchActorPhotoUrl(actorId: actorId);
  }

  NotificationItem _fromMap(Map<String, dynamic> map) {
    final ts = map['createdAt'];
    DateTime createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return NotificationItem(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? '',
      actorId: map['actorId'] as String? ?? '',
      actorDisplayName: map['actorDisplayName'] as String? ?? '',
      postId: map['postId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: createdAt,
    );
  }
}
