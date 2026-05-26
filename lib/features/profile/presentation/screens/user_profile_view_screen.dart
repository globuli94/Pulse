// lib/features/profile/presentation/screens/user_profile_view_screen.dart
//
// UserProfileViewScreen — read-only profile view for any user via /profile/:uid.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../chat/domain/repositories/chat_repository.dart';
import '../../../follows/presentation/bloc/follow_bloc.dart';
import '../bloc/user_profile_bloc.dart';
import '../widgets/profile_avatar.dart';

/// Read-only profile view for any user, reachable at `/profile/:uid`.
///
/// [UserProfileBloc] and [FollowBloc] are provided in the route builder
/// (screen-scoped). Pass [viewedUid] and [currentUserId] from the route
/// builder so the screen can hide the follow button on own profiles.
class UserProfileViewScreen extends StatelessWidget {
  /// Creates a [UserProfileViewScreen].
  const UserProfileViewScreen({
    super.key,
    required this.viewedUid,
    required this.currentUserId,
  });

  /// UID of the profile being viewed.
  final String viewedUid;

  /// UID of the currently authenticated user.
  final String currentUserId;

  /// Whether this screen is displaying the authenticated user's own profile.
  bool get _isOwnProfile => currentUserId == viewedUid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserProfileBloc, UserProfileState>(
      builder: (context, state) {
        if (state is UserProfileLoading || state is UserProfileInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is UserProfileError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(state.message)),
          );
        }

        if (state is UserProfileLoaded) {
          final profile = state.profile;
          return Scaffold(
            appBar: AppBar(title: Text(profile.displayName)),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfileAvatar(
                        avatarUrl: profile.avatarUrl,
                        radius: 80,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.displayName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.bio.isNotEmpty ? profile.bio : 'No bio yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${profile.postCount} posts',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.followerCount} followers · '
                        '${profile.followingCount} following',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (!_isOwnProfile) ...[
                        const SizedBox(height: 16),
                        BlocConsumer<FollowBloc, FollowState>(
                          listener: (context, followState) {
                            // After a successful follow/unfollow, refresh the
                            // profile so follower/following counts update.
                            if (followState is FollowLoaded) {
                              context
                                  .read<UserProfileBloc>()
                                  .add(UserProfileLoadRequested(uid: viewedUid));
                            }
                          },
                          builder: (context, followState) {
                            if (followState is FollowLoading ||
                                followState is FollowInitial) {
                              return const CircularProgressIndicator();
                            }

                            if (followState is FollowLoaded) {
                              if (followState.isFollowing) {
                                return OutlinedButton(
                                  onPressed: () =>
                                      context.read<FollowBloc>().add(
                                            UnfollowRequested(
                                              followerId: currentUserId,
                                              followeeId: viewedUid,
                                            ),
                                          ),
                                  child: const Text('Unfollow'),
                                );
                              } else {
                                return ElevatedButton(
                                  onPressed: () =>
                                      context.read<FollowBloc>().add(
                                            FollowRequested(
                                              followerId: currentUserId,
                                              followeeId: viewedUid,
                                            ),
                                          ),
                                  child: const Text('Follow'),
                                );
                              }
                            }

                            // FollowFailure — show a retry button.
                            return ElevatedButton(
                              onPressed: () =>
                                  context.read<FollowBloc>().add(
                                        FollowStatusCheckRequested(
                                          followerId: currentUserId,
                                          followeeId: viewedUid,
                                        ),
                                      ),
                              child: const Text('Retry'),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final chatRepository =
                                context.read<ChatRepository>();
                            final conversationId =
                                await chatRepository.getOrCreateConversation(
                              currentUserId: currentUserId,
                              otherUserId: viewedUid,
                            );
                            if (context.mounted) {
                              context.push(
                                '/chat/$conversationId',
                                extra: {
                                  'currentUserId': currentUserId,
                                  'otherUserId': viewedUid,
                                  'otherUserDisplayName':
                                      profile.displayName,
                                },
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Message'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
