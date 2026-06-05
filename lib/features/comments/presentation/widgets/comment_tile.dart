// lib/features/comments/presentation/widgets/comment_tile.dart
//
// CommentTile — a single row in the comments list.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/profile/domain/repositories/profile_repository.dart';
import '../../../../features/profile/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/comment.dart';

/// A single tile in the comments list.
///
/// Resolves the author's display name and avatar live from [ProfileRepository].
class CommentTile extends StatelessWidget {
  /// Creates a [CommentTile].
  const CommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<({String displayName, String? avatarUrl})>(
            stream: context
                .read<ProfileRepository>()
                .watchUserDisplayInfo(comment.authorId),
            builder: (context, snap) {
              final avatarUrl = snap.data?.avatarUrl;
              return ProfileAvatar(avatarUrl: avatarUrl, radius: 18);
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<({String displayName, String? avatarUrl})>(
                  stream: context
                      .read<ProfileRepository>()
                      .watchUserDisplayInfo(comment.authorId),
                  builder: (context, snap) {
                    final displayName = snap.data?.displayName ?? '';
                    return Text(
                      displayName,
                      style: theme.textTheme.titleSmall,
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  _relativeTime(comment.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
