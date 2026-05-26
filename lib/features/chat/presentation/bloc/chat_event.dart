// lib/features/chat/presentation/bloc/chat_event.dart

part of 'chat_bloc.dart';

/// Base class for all [ChatBloc] events.
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when [ChatScreen] opens to begin the message stream and mark
/// the conversation as read.
class ChatStarted extends ChatEvent {
  /// Creates a [ChatStarted] event.
  const ChatStarted({
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserId,
  });

  /// ID of the conversation being opened.
  final String conversationId;

  /// UID of the authenticated user viewing the chat.
  final String currentUserId;

  /// UID of the other participant (used to update unreadCounts on send).
  final String otherUserId;

  @override
  List<Object?> get props => [conversationId, currentUserId, otherUserId];
}

/// Fired when the user taps the send button.
class MessageSent extends ChatEvent {
  /// Creates a [MessageSent] event.
  const MessageSent({
    required this.conversationId,
    required this.senderId,
    required this.otherUserId,
    required this.text,
  });

  /// ID of the conversation.
  final String conversationId;

  /// UID of the sender.
  final String senderId;

  /// UID of the recipient (for unread count increment).
  final String otherUserId;

  /// Message text content.
  final String text;

  @override
  List<Object?> get props => [conversationId, senderId, otherUserId, text];
}
