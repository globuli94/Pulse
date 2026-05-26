// lib/features/chat/presentation/bloc/conversations_state.dart

part of 'conversations_bloc.dart';

/// Base class for all [ConversationsBloc] states.
abstract class ConversationsState extends Equatable {
  const ConversationsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before the stream has been started.
class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

/// Stream is starting; conversations not yet received.
class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

/// Conversations successfully received from Firestore.
class ConversationsLoaded extends ConversationsState {
  const ConversationsLoaded({required this.conversations});

  /// The current list of conversations, ordered by `lastMessageAt` DESC.
  final List<Conversation> conversations;

  @override
  List<Object?> get props => [conversations];
}

/// An error occurred while loading conversations.
class ConversationsError extends ConversationsState {
  const ConversationsError({required this.message});

  /// Human-readable error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
