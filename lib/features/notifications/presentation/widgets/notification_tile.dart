// lib/features/notifications/presentation/widgets/notification_tile.dart
//
// NotificationTile — a single row in the notifications list.

import 'package:flutter/material.dart';

import '../../domain/entities/notification_item.dart';

/// A single tile in the notifications list.
///
/// Shows the actor's avatar, a human-readable message, and a relative
/// timestamp. Unread notifications have a tinted background.
class NotificationTile extends StatelessWidget {
  /// Creates a [NotificationTile].
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationItem notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = notification.type == 'like'
        ? '${notification.actorDisplayName} liked your post'
        : '${notification.actorDisplayName} started following you';

    return ListTile(
      tileColor: notification.isRead
          ? null
          : Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.15),
      leading: CircleAvatar(
        backgroundImage: notification.actorPhotoUrl != null
            ? NetworkImage(notification.actorPhotoUrl!)
            : null,
        child: notification.actorPhotoUrl == null
            ? Text(
                notification.actorDisplayName.isNotEmpty
                    ? notification.actorDisplayName[0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(text),
      subtitle: Text(_formatTime(notification.createdAt)),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
