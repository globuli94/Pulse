// lib/features/chat/domain/repositories/chat_repository.dart
//
// ChatRepository — abstract interface for all chat operations.

import '../entities/conversation.dart';
import '../entities/message.dart';

/// Abstract repository interface for 1-to-1 chat operations.
///
/// Zero Firebase imports — implementations live in the data layer.
abstract class ChatRepository {
  /// Returns a real-time stream of conversations for [userId], ordered by
  /// `lastMessageAt` descending.
  ///
  /// Each [Conversation] includes the other participant's display name and
  /// avatar resolved via a `users` collection join.
  Stream<List<Conversation>> watchConversations(String userId);

  /// Returns a real-time stream of messages in [conversationId], ordered by
  /// `createdAt` ascending.
  Stream<List<Message>> watchMessages(String conversationId);

  /// Sends a message in [conversationId] from [senderId] to [otherUserId].
  ///
  /// Atomically:
  /// 1. Writes the message document to `conversations/{id}/messages`.
  /// 2. Updates `conversations/{id}.lastMessageText` and `lastMessageAt`.
  /// 3. Increments `conversations/{id}.unreadCounts[otherUserId]` by 1.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String otherUserId,
    required String text,
  });

  /// Finds an existing conversation between [currentUserId] and [otherUserId].
  /// Creates a new one if none exists.
  ///
  /// Returns the conversation document ID.
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  });

  /// Resets `unreadCounts[userId]` to 0 in [conversationId].
  ///
  /// Called when the user opens a conversation.
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  });
}
