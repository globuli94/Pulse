// lib/features/chat/presentation/bloc/conversations_event.dart

part of 'conversations_bloc.dart';

/// Base class for all [ConversationsBloc] events.
abstract class ConversationsEvent extends Equatable {
  const ConversationsEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when [ConversationsScreen] is created to start the stream.
class ConversationsStarted extends ConversationsEvent {
  /// Creates a [ConversationsStarted] event.
  const ConversationsStarted({required this.userId});

  /// UID of the current authenticated user.
  final String userId;

  @override
  List<Object?> get props => [userId];
}
