// lib/features/chat/domain/entities/message.dart
//
// Message — domain entity for a single message in a conversation.

import 'package:equatable/equatable.dart';

/// Immutable entity representing a single message inside a conversation.
class Message extends Equatable {
  /// Creates a [Message].
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  /// Firestore document ID.
  final String id;

  /// Firebase Auth UID of the message sender.
  final String senderId;

  /// Text content of the message.
  final String text;

  /// Timestamp when the message was sent.
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, senderId, text, createdAt];
}
