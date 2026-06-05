// lib/features/comments/presentation/screens/comments_screen.dart
//
// CommentsScreen — displays comments for a single post and allows adding new ones.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/comments_bloc.dart';
import '../widgets/comment_tile.dart';

/// Screen that shows comments for [postId] and allows the current user to add one.
class CommentsScreen extends StatefulWidget {
  /// Creates a [CommentsScreen].
  const CommentsScreen({
    super.key,
    required this.postId,
    required this.currentUserId,
  });

  final String postId;
  final String currentUserId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<CommentsBloc>().add(
          CommentAddRequested(
            postId: widget.postId,
            authorId: widget.currentUserId,
            text: text,
          ),
        );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<CommentsBloc, CommentsState>(
              builder: (context, state) {
                if (state is CommentsLoading || state is CommentsInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CommentsError) {
                  return Center(child: Text(state.message));
                }
                if (state is CommentsLoaded) {
                  final comments = state.comments;
                  if (comments.isEmpty) {
                    return const Center(child: Text('No comments yet.'));
                  }
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) => CommentTile(
                      key: ValueKey(comments[index].id),
                      comment: comments[index],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment…',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  tooltip: 'Send',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
