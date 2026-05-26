// lib/features/chat/presentation/bloc/chat_state.dart

part of 'chat_bloc.dart';

/// Base class for all [ChatBloc] states.
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// Initial state before the message stream has been started.
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Message stream is starting.
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Messages successfully received from Firestore.
class ChatLoaded extends ChatState {
  const ChatLoaded({required this.messages});

  /// The current ordered list of messages (oldest first).
  final List<Message> messages;

  @override
  List<Object?> get props => [messages];
}

/// An error occurred while loading or sending messages.
class ChatError extends ChatState {
  const ChatError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
