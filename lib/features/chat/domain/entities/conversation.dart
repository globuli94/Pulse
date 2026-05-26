// lib/features/chat/domain/entities/conversation.dart
//
// Conversation — domain entity for a 1-to-1 DM conversation.

import 'package:equatable/equatable.dart';

/// Immutable entity representing a direct-message conversation between two users.
///
/// [otherUserDisplayName] and [otherUserAvatarUrl] are resolved in the data
/// layer by joining against the `users` collection so the presentation layer
/// receives a self-contained object.
class Conversation extends Equatable {
  /// Creates a [Conversation].
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.otherUserDisplayName,
    this.otherUserAvatarUrl,
    required this.lastMessageText,
    required this.lastMessageAt,
    required this.unreadCounts,
  });

  /// Firestore document ID.
  final String id;

  /// UIDs of both participants.
  final List<String> participantIds;

  /// Display name of the other participant (joined from `users` collection).
  final String otherUserDisplayName;

  /// Avatar URL of the other participant; null if not set.
  final String? otherUserAvatarUrl;

  /// Preview text of the most recent message.
  final String lastMessageText;

  /// Timestamp of the most recent message; used for ordering.
  final DateTime lastMessageAt;

  /// Maps each participant UID to their unread message count.
  final Map<String, int> unreadCounts;

  @override
  List<Object?> get props => [
        id,
        participantIds,
        otherUserDisplayName,
        otherUserAvatarUrl,
        lastMessageText,
        lastMessageAt,
        unreadCounts,
      ];
}
