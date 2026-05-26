// lib/features/chat/presentation/bloc/conversations_bloc.dart
//
// ConversationsBloc — manages the real-time conversations list.

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';

part 'conversations_event.dart';
part 'conversations_state.dart';

/// BLoC that subscribes to the Firestore conversations stream for the current
/// user and emits [ConversationsLoaded] on every update.
///
/// Screen-scoped: provided and started by [ConversationsScreen].
class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  /// Creates a [ConversationsBloc].
  ConversationsBloc({required ChatRepository repository})
      : _repository = repository,
        super(const ConversationsInitial()) {
    on<ConversationsStarted>(_onStarted);
  }

  final ChatRepository _repository;

  Future<void> _onStarted(
    ConversationsStarted event,
    Emitter<ConversationsState> emit,
  ) async {
    emit(const ConversationsLoading());
    await emit.onEach<List<Conversation>>(
      _repository.watchConversations(event.userId),
      onData: (conversations) =>
          emit(ConversationsLoaded(conversations: conversations)),
      onError: (e, _) =>
          emit(ConversationsError(message: e.toString())),
    );
  }
}
