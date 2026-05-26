// lib/features/chat/presentation/bloc/chat_bloc.dart
//
// ChatBloc — manages real-time messages and message sending for a conversation.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

/// BLoC that subscribes to the Firestore messages stream for a single
/// conversation and handles sending messages.
///
/// Screen-scoped: provided and started by [ChatScreen].
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  /// Creates a [ChatBloc].
  ChatBloc({required ChatRepository repository})
      : _repository = repository,
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<MessageSent>(_onMessageSent);
  }

  final ChatRepository _repository;

  /// Stored so [MessageSent] can reference it without repeating from the event.
  String _otherUserId = '';

  Future<void> _onStarted(
    ChatStarted event,
    Emitter<ChatState> emit,
  ) async {
    _otherUserId = event.otherUserId;
    emit(const ChatLoading());

    // Mark conversation as read when it is opened.
    try {
      await _repository.markAsRead(
        conversationId: event.conversationId,
        userId: event.currentUserId,
      );
    } catch (_) {
      // Non-fatal; continue loading messages even if mark-read fails.
    }

    await emit.onEach<List<Message>>(
      _repository.watchMessages(event.conversationId),
      onData: (messages) => emit(ChatLoaded(messages: messages)),
      onError: (e, _) => emit(ChatError(message: e.toString())),
    );
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.sendMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        otherUserId: event.otherUserId.isNotEmpty
            ? event.otherUserId
            : _otherUserId,
        text: event.text,
      );
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }
}
