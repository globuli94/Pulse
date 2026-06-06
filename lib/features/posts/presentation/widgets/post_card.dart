// lib/features/posts/presentation/widgets/post_card.dart
//
// PostCard — displays a single post in the feed.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/comments/domain/repositories/comments_repository.dart';
import '../../../../features/comments/presentation/bloc/comment_count_cubit.dart';
import '../../../../features/home/presentation/bloc/shell_tab_cubit.dart';
import '../../../../features/profile/domain/repositories/profile_repository.dart';
import '../../../../features/profile/presentation/widgets/profile_avatar.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/posts_repository.dart';
import '../bloc/like_bloc.dart';
import '../bloc/like_event.dart';
import '../bloc/like_state.dart';
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
    final authState = context.read<AuthBloc>().state;
    final currentUid = authState is Authenticated ? authState.user.uid : null;

    return MultiBlocProvider(
      providers: [
        BlocProvider<LikeBloc>(
          key: ValueKey('like_${post.id}'),
          create: (ctx) => LikeBloc(repository: ctx.read<PostsRepository>())
            ..add(LikeInitialised(
              postId: post.id,
              userId: currentUid ?? '',
              initialLikeCount: post.likeCount,
            )),
        ),
        BlocProvider<CommentCountCubit>(
          key: ValueKey('comment_count_${post.id}'),
          create: (ctx) => CommentCountCubit(
            repository: ctx.read<CommentsRepository>(),
          )..startWatching(post.id),
        ),
      ],
      child: _PostCardBody(post: post, currentUid: currentUid),
    );
  }
}

class _PostCardBody extends StatelessWidget {
  const _PostCardBody({required this.post, required this.currentUid});

  final Post post;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = currentUid != null && currentUid == post.userId;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: avatar + name + timestamp + optional delete
            Row(
              children: [
                GestureDetector(
                  // BUG-001f: tapping own profile switches to the Profile tab
                  // instead of opening the read-only OtherProfileScreen.
                  onTap: () {
                    if (post.userId == currentUid) {
                      context.read<ShellTabCubit>().switchToTab(3);
                    } else {
                      context.push('/profile/${post.userId}');
                    }
                  },
                  child: StreamBuilder<({String displayName, String? avatarUrl})>(
                    stream: context
                        .read<ProfileRepository>()
                        .watchUserDisplayInfo(post.userId),
                    builder: (context, snap) {
                      final displayName = snap.data?.displayName ?? '';
                      final avatarUrl = snap.data?.avatarUrl;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProfileAvatar(avatarUrl: avatarUrl, radius: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
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
                        ],
                      );
                    },
                  ),
                ),
                const Spacer(),
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
            const SizedBox(height: 12),
            // Like and comment buttons on the same row
            Row(
              children: [
                _LikeButton(
                  postId: post.id,
                  userId: currentUid ?? '',
                ),
                _CommentCountButton(postId: post.id),
              ],
            ),
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

class _CommentCountButton extends StatelessWidget {
  const _CommentCountButton({required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentCountCubit, int>(
      builder: (context, count) {
        return GestureDetector(
          onTap: () => context.push('/post/$postId/comments'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.postId, required this.userId});
  final String postId;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LikeBloc, LikeState>(
      builder: (context, state) {
        if (state is LikeLoading || state is LikeInitial) {
          return const SizedBox(height: 32, width: 64);
        }
        final isLiked = state is LikeLoaded ? state.isLiked : false;
        final likeCount = state is LikeLoaded ? state.likeCount : 0;
        return GestureDetector(
          onTap: () => context.read<LikeBloc>().add(
                LikeToggleRequested(postId: postId, userId: userId),
              ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$likeCount',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
