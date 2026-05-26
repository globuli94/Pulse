// lib/features/chat/data/datasources/chat_firebase_data_source.dart
//
// ChatFirebaseDataSource — Firestore implementation of ChatRemoteDataSource.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import 'chat_remote_data_source.dart';

/// Firestore-backed implementation of [ChatRemoteDataSource].
class ChatFirebaseDataSource implements ChatRemoteDataSource {
  /// Creates a [ChatFirebaseDataSource].
  ChatFirebaseDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final conversations = <Conversation>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participantIds =
            List<String>.from(data['participantIds'] as List<dynamic>);
        final otherUserId =
            participantIds.firstWhere((id) => id != userId, orElse: () => '');

        String otherUserDisplayName = '';
        String? otherUserAvatarUrl;

        if (otherUserId.isNotEmpty) {
          final userDoc =
              await _firestore.collection('users').doc(otherUserId).get();
          if (userDoc.exists && userDoc.data() != null) {
            otherUserDisplayName =
                userDoc.data()!['displayName'] as String? ?? '';
            otherUserAvatarUrl = userDoc.data()!['avatarUrl'] as String?;
          }
        }

        final lastMessageAt =
            (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final unreadCountsRaw =
            data['unreadCounts'] as Map<String, dynamic>? ?? {};
        final unreadCounts =
            unreadCountsRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

        conversations.add(Conversation(
          id: doc.id,
          participantIds: participantIds,
          otherUserDisplayName: otherUserDisplayName,
          otherUserAvatarUrl: otherUserAvatarUrl,
          lastMessageText: data['lastMessageText'] as String? ?? '',
          lastMessageAt: lastMessageAt,
          unreadCounts: unreadCounts,
        ));
      }
      return conversations;
    });
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Message(
                id: doc.id,
                senderId: data['senderId'] as String,
                text: data['text'] as String,
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.now(),
              );
            }).toList());
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String otherUserId,
    required String text,
  }) async {
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    final batch = _firestore.batch();
    batch.set(messageRef, {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(conversationRef, {
      'lastMessageText': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts.$otherUserId': FieldValue.increment(1),
    });
    await batch.commit();
  }

  @override
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final snapshot = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    // Filter client-side for a conversation that also contains otherUserId.
    for (final doc in snapshot.docs) {
      final ids =
          List<String>.from(doc.data()['participantIds'] as List<dynamic>);
      if (ids.contains(otherUserId)) return doc.id;
    }

    // No existing conversation — create one.
    final conversationRef = _firestore.collection('conversations').doc();
    await conversationRef.set({
      'participantIds': [currentUserId, otherUserId],
      'lastMessageText': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {currentUserId: 0, otherUserId: 0},
    });
    return conversationRef.id;
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.$userId': 0,
    });
  }
}
