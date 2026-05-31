// lib/features/chat/presentation/screens/chat_screen.dart
//
// ChatScreen — real-time 1-to-1 message view.
//
// ChatBloc is screen-scoped: provided in the route builder (app_router.dart).
// This screen is the consumer — it never creates the BLoC itself.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../../domain/entities/message.dart';

/// Full-screen chat view for a single conversation.
///
/// [ChatBloc] is provided by the route builder in `app_router.dart`.
/// [conversationId], [currentUserId], and [otherUserId] are passed from the
/// route so the BLoC can be started with the correct parameters.
class ChatScreen extends StatefulWidget {
  /// Creates a [ChatScreen].
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserDisplayName,
    this.otherUserAvatarUrl,
  });

  /// ID of the conversation being viewed.
  final String conversationId;

  /// UID of the authenticated user.
  final String currentUserId;

  /// UID of the other participant.
  final String otherUserId;

  /// Display name of the other participant shown in the AppBar.
  final String otherUserDisplayName;

  /// Avatar URL of the other participant; null if not set.
  final String? otherUserAvatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ChatStarted(
          conversationId: widget.conversationId,
          currentUserId: widget.currentUserId,
          otherUserId: widget.otherUserId,
        ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(MessageSent(
          conversationId: widget.conversationId,
          senderId: widget.currentUserId,
          otherUserId: widget.otherUserId,
          text: text,
        ));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otherUserDisplayName,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                // Scroll to bottom when new messages arrive.
                if (state is ChatLoaded && _scrollController.hasClients) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
              builder: (context, state) {
                if (state is ChatLoading || state is ChatInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ChatError) {
                  return Center(child: Text(state.message));
                }

                if (state is ChatLoaded) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Say hello!'),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isOwn = message.senderId == widget.currentUserId;
                      return _MessageBubble(
                        message: message,
                        isOwn: isOwn,
                        otherUserAvatarUrl:
                            isOwn ? null : widget.otherUserAvatarUrl,
                        otherUserDisplayName: widget.otherUserDisplayName,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          _MessageInputBar(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// A single message bubble aligned left (theirs) or right (own).
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isOwn,
    required this.otherUserDisplayName,
    this.otherUserAvatarUrl,
  });

  final Message message;
  final bool isOwn;
  final String otherUserDisplayName;
  final String? otherUserAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.65,
      ),
      decoration: BoxDecoration(
        color: isOwn ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isOwn ? 16 : 4),
          bottomRight: Radius.circular(isOwn ? 4 : 16),
        ),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: isOwn ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
    );

    if (isOwn) {
      return Align(
        alignment: Alignment.centerRight,
        child: bubble,
      );
    }

    final initial = otherUserDisplayName.isNotEmpty
        ? otherUserDisplayName[0].toUpperCase()
        : '?';
    final avatar = CircleAvatar(
      radius: 16,
      backgroundImage:
          otherUserAvatarUrl != null ? NetworkImage(otherUserAvatarUrl!) : null,
      child: otherUserAvatarUrl == null ? Text(initial) : null,
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: 6),
          bubble,
        ],
      ),
    );
  }
}

/// Text input bar at the bottom of the chat screen.
class _MessageInputBar extends StatelessWidget {
  const _MessageInputBar({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
