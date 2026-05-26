// lib/features/chat/presentation/bloc/unread_count_cubit.dart
//
// UnreadCountCubit — tracks the total unread message count across all
// conversations for the current user.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/chat_repository.dart';

/// Cubit that emits the total number of unread messages across all
/// conversations for [currentUserId].
///
/// Provided globally in main.dart so the ShellScreen nav badge and any other
/// widget in the tree can observe it.
class UnreadCountCubit extends Cubit<int> {
  /// Creates an [UnreadCountCubit].
  UnreadCountCubit({
    required ChatRepository repository,
    required String currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        super(0);

  final ChatRepository _repository;
  final String _currentUserId;
  StreamSubscription<dynamic>? _subscription;

  /// Starts listening to the conversations stream and updating the unread total.
  void watchUnreadCount() {
    if (_currentUserId.isEmpty) return;
    _subscription = _repository.watchConversations(_currentUserId).listen(
      (conversations) {
        final total = conversations.fold<int>(
          0,
          (sum, c) => sum + (c.unreadCounts[_currentUserId] ?? 0),
        );
        emit(total);
      },
      onError: (_) => emit(0),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
