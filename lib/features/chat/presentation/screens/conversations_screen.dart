// lib/features/chat/presentation/screens/conversations_screen.dart
//
// ConversationsScreen — lists all active conversations for the current user.
//
// ConversationsBloc is screen-scoped: provided here rather than in main.dart
// because it is only needed by this tab.  The inner body widget
// (_ConversationsBody) is the consumer so the provider/consumer split is
// respected.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../bloc/conversations_bloc.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';

/// Conversations tab screen — shows all DM conversations for the current user.
///
/// Provides its own [ConversationsBloc] (screen-scoped).
/// The body widget [_ConversationsBody] is the consumer.
class ConversationsScreen extends StatelessWidget {
  /// Creates a [ConversationsScreen].
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is Authenticated ? authState.user.uid : '';

    return BlocProvider<ConversationsBloc>(
      create: (context) => ConversationsBloc(
        repository: context.read<ChatRepository>(),
      )..add(ConversationsStarted(userId: currentUserId)),
      child: _ConversationsBody(currentUserId: currentUserId),
    );
  }
}

/// Inner body that consumes [ConversationsBloc].
class _ConversationsBody extends StatelessWidget {
  const _ConversationsBody({required this.currentUserId});

  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ConversationsBloc, ConversationsState>(
        builder: (context, state) {
          if (state is ConversationsLoading || state is ConversationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConversationsError) {
            return Center(child: Text(state.message));
          }

          if (state is ConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return const Center(
                child: Text('No conversations yet.'),
              );
            }
            return ListView.separated(
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  currentUserId: currentUserId,
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// A single row in the conversations list.
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
  });

  final Conversation conversation;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCounts[currentUserId] ?? 0;
    final subtitle = conversation.lastMessageText.isEmpty
        ? 'Start a conversation'
        : conversation.lastMessageText;

    return ListTile(
      leading: ProfileAvatar(
        avatarUrl: conversation.otherUserAvatarUrl,
        radius: 24,
      ),
      title: Text(
        conversation.otherUserDisplayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatRelativeTime(conversation.lastMessageAt),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          if (unread > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.push(
        '/chat/${conversation.id}',
        extra: {
          'otherUserId': conversation.participantIds
              .firstWhere((id) => id != currentUserId, orElse: () => ''),
          'otherUserDisplayName': conversation.otherUserDisplayName,
          'currentUserId': currentUserId,
        },
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
