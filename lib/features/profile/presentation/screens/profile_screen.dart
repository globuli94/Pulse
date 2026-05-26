// lib/features/profile/presentation/screens/profile_screen.dart
//
// ProfileScreen — own profile tab shown to the authenticated user.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_posts_bloc.dart';
import '../widgets/profile_avatar.dart';

/// Displays the authenticated user's own profile, including their posts.
///
/// Reads from the global [ProfileBloc] and [ProfilePostsBloc]. On build it
/// dispatches [ProfileLoadRequested] and [ProfilePostsLoadRequested] with the
/// authenticated user's UID.
class ProfileScreen extends StatefulWidget {
  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _loadedUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final uid = authState.user.uid;
      if (_loadedUid != uid) {
        _loadedUid = uid;
        context.read<ProfileBloc>().add(ProfileLoadRequested(uid: uid));
        context
            .read<ProfilePostsBloc>()
            .add(ProfilePostsLoadRequested(uid: uid));
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account, posts, and avatar. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<ProfileBloc>().add(const ProfileDeleteAccountRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // ProfileSignedOut and ProfileAccountDeleted: AuthBloc stream will
        // emit Unauthenticated automatically, and the router guard will
        // redirect to /login. No manual navigation needed.
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ProfileError) {
            return Scaffold(
              body: Center(child: Text(state.message)),
            );
          }

          final profile = switch (state) {
            ProfileLoaded(:final profile) => profile,
            ProfileUpdating(:final profile) => profile,
            ProfileUpdateSuccess(:final profile) => profile,
            _ => null,
          };

          if (profile == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            body: SafeArea(
              child: _ProfileScreenBody(
                profile: profile,
                onEditProfile: () => context.push('/edit-profile'),
                onSignOut: () => context
                    .read<ProfileBloc>()
                    .add(const ProfileSignOutRequested()),
                onDeleteAccount: () => _confirmDeleteAccount(context),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileScreenBody extends StatelessWidget {
  const _ProfileScreenBody({
    required this.profile,
    required this.onEditProfile,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  final UserProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilePostsBloc, ProfilePostsState>(
      builder: (context, postsState) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ProfileAvatar(avatarUrl: profile.avatarUrl, radius: 80),
                    const SizedBox(height: 16),
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.bio.isNotEmpty ? profile.bio : 'No bio yet.',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              context.push('/followers/${profile.uid}'),
                          child: Text(
                            '${profile.followerCount} followers',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                        Text(
                          ' · ',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.push('/following/${profile.uid}'),
                          child: Text(
                            '${profile.followingCount} following',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: onEditProfile,
                      child: const Text('Edit Profile'),
                    ),
                    TextButton(
                      onPressed: onSignOut,
                      child: const Text('Sign Out'),
                    ),
                    TextButton(
                      onPressed: onDeleteAccount,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete Account'),
                    ),
                    const Divider(height: 32),
                  ],
                ),
              ),
            ),
            if (postsState is ProfilePostsLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (postsState is ProfilePostsError)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text(postsState.message)),
                ),
              )
            else if (postsState is ProfilePostsLoaded) ...[
              if (postsState.posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No posts yet.')),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        PostCard(post: postsState.posts[index]),
                    childCount: postsState.posts.length,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
