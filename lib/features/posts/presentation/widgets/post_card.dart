// lib/features/posts/presentation/widgets/post_card.dart
//
// PostCard — displays a single post in the feed.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/profile/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/post.dart';
import '../bloc/posts_feed_bloc.dart';

/// Card widget that renders a single [Post].
///
/// Provides a delete button only when the authenticated user is the author.
class PostCard extends StatelessWidget {
  /// Creates a [PostCard].
  const PostCard({super.key, required this.post});

  /// The post to display.
  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final currentUid = authState is Authenticated ? authState.user.uid : null;
    final isOwner = currentUid != null && currentUid == post.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: avatar + name + timestamp + optional delete
            Row(
              children: [
                ProfileAvatar(avatarUrl: post.avatarUrl, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.displayName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        _relativeTime(post.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete post',
                    onPressed: () => context.read<PostsFeedBloc>().add(
                          PostsDeleteRequested(
                            postId: post.id,
                            userId: post.userId,
                          ),
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Post text
            Text(post.text, style: theme.textTheme.bodyMedium),
            // Post image (if any)
            if (post.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Returns a human-readable relative timestamp (e.g. "2h ago").
  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
