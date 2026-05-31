// lib/features/search/presentation/widgets/user_search_result_tile.dart
//
// UserSearchResultTile — list tile for a single user-search result.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/bloc/shell_tab_cubit.dart';
import '../../../follows/domain/repositories/follows_repository.dart';
import '../../../follows/presentation/bloc/follow_bloc.dart';
import '../../../profile/domain/entities/user_profile.dart';

/// A list tile that shows a user's avatar, display name, and a follow button.
///
/// Each tile provides its own [FollowBloc] (per-item scope) because multiple
/// tiles are visible on screen simultaneously.  A [ValueKey] on the
/// [BlocProvider] ensures Flutter rebuilds correctly when list order changes.
class UserSearchResultTile extends StatelessWidget {
  /// Creates a [UserSearchResultTile].
  const UserSearchResultTile({
    required this.user,
    required this.currentUserId,
    super.key,
  });

  /// The user profile to display.
  final UserProfile user;

  /// UID of the authenticated user — used to hide the button on own profile.
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FollowBloc>(
      key: ValueKey(user.uid),
      create: (context) => FollowBloc(
        followsRepository: context.read<FollowsRepository>(),
      )..add(
          FollowStatusCheckRequested(
            followerId: currentUserId,
            followeeId: user.uid,
          ),
        ),
      child: _UserSearchResultTileBody(
        user: user,
        currentUserId: currentUserId,
      ),
    );
  }
}

/// Inner widget that consumes [FollowBloc] (never provides it).
class _UserSearchResultTileBody extends StatelessWidget {
  const _UserSearchResultTileBody({
    required this.user,
    required this.currentUserId,
  });

  final UserProfile user;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
              )
            : null,
      ),
      title: Text(user.displayName),
      trailing: user.uid == currentUserId
          ? null
          : BlocBuilder<FollowBloc, FollowState>(
              builder: (context, state) {
                if (state is FollowLoaded) {
                  if (state.isFollowing) {
                    return OutlinedButton(
                      onPressed: () => context.read<FollowBloc>().add(
                            UnfollowRequested(
                              followerId: currentUserId,
                              followeeId: user.uid,
                            ),
                          ),
                      child: const Text('Unfollow'),
                    );
                  } else {
                    return FilledButton(
                      onPressed: () => context.read<FollowBloc>().add(
                            FollowRequested(
                              followerId: currentUserId,
                              followeeId: user.uid,
                            ),
                          ),
                      child: const Text('Follow'),
                    );
                  }
                }

                if (state is FollowFailure) {
                  return TextButton(
                    onPressed: () => context.read<FollowBloc>().add(
                          FollowStatusCheckRequested(
                            followerId: currentUserId,
                            followeeId: user.uid,
                          ),
                        ),
                    child: const Text('Retry'),
                  );
                }

                // FollowInitial or FollowLoading
                return const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
      // BUG-001f: tapping own entry in search results switches to Profile tab.
      onTap: () {
        if (user.uid == currentUserId) {
          context.read<ShellTabCubit>().switchToTab(3);
        } else {
          context.push('/profile/${user.uid}');
        }
      },
    );
  }
}
