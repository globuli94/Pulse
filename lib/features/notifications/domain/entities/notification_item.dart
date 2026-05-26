// lib/features/notifications/domain/entities/notification_item.dart
//
// NotificationItem — domain entity for a single in-app notification.

/// A single in-app notification for a user.
///
/// [type] is either `'like'` or `'follow'`. [postId] is non-null when
/// [type] is `'like'`.
class NotificationItem {
  /// Creates a [NotificationItem].
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.actorId,
    required this.actorDisplayName,
    this.actorPhotoUrl,
    this.postId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String actorId;
  final String actorDisplayName;
  final String? actorPhotoUrl;
  final String? postId;
  final bool isRead;
  final DateTime createdAt;

  /// Returns a copy with optional field overrides.
  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        userId: userId,
        type: type,
        actorId: actorId,
        actorDisplayName: actorDisplayName,
        actorPhotoUrl: actorPhotoUrl,
        postId: postId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}
