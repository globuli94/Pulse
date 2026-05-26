// lib/features/chat/data/repositories/chat_repository_impl.dart
//
// ChatRepositoryImpl — concrete implementation of ChatRepository.

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

/// Concrete implementation of [ChatRepository] backed by [ChatRemoteDataSource].
class ChatRepositoryImpl implements ChatRepository {
  /// Creates a [ChatRepositoryImpl].
  ChatRepositoryImpl({required ChatRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final ChatRemoteDataSource _dataSource;

  @override
  Stream<List<Conversation>> watchConversations(String userId) =>
      _dataSource.watchConversations(userId);

  @override
  Stream<List<Message>> watchMessages(String conversationId) =>
      _dataSource.watchMessages(conversationId);

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String otherUserId,
    required String text,
  }) =>
      _dataSource.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        otherUserId: otherUserId,
        text: text,
      );

  @override
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) =>
      _dataSource.getOrCreateConversation(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) =>
      _dataSource.markAsRead(conversationId: conversationId, userId: userId);
}
