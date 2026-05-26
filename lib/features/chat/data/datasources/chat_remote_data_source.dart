// lib/features/chat/data/datasources/chat_remote_data_source.dart
//
// ChatRemoteDataSource — abstract interface for raw Firestore chat operations.

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

/// Abstract data source interface for chat operations against Firestore.
///
/// Implementations must return only domain entities (no Firestore types).
abstract class ChatRemoteDataSource {
  /// Returns a real-time stream of conversations for [userId].
  Stream<List<Conversation>> watchConversations(String userId);

  /// Returns a real-time stream of messages in [conversationId].
  Stream<List<Message>> watchMessages(String conversationId);

  /// Sends a message and updates the conversation metadata atomically.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String otherUserId,
    required String text,
  });

  /// Finds or creates a conversation between [currentUserId] and [otherUserId].
  /// Returns the conversation ID.
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  });

  /// Resets `unreadCounts[userId]` to 0 in [conversationId].
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  });
}
