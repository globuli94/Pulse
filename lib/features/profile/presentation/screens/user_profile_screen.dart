// lib/features/profile/presentation/screens/user_profile_screen.dart
//
// UserProfileScreen — read-only view of any user's profile.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile_bloc.dart';
import '../widgets/profile_avatar_widget.dart';

/// Read-only profile screen for any user, accessed via the `/profile/:uid` route.
///
/// The [ProfileBloc] is provided by the route builder in `app_router.dart` —
/// this widget must NOT provide its own BLoC.
class UserProfileScreen extends StatelessWidget {
  /// Creates a [UserProfileScreen].
  const UserProfileScreen({super.key, required this.uid});

  /// The uid of the user whose profile is being viewed.
  final String uid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final title = state is ProfileLoaded
            ? state.profile.displayName
            : 'Profile';

        if (state is ProfileLoading || state is ProfileInitial) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileLoaded) {
          final profile = state.profile;
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ProfileAvatarWidget(
                    avatarUrl: profile.avatarUrl,
                    radius: 50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    '@${profile.username}',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PostCountRow(postCount: profile.postCount),
                ],
              ),
            ),
          );
        }

        if (state is ProfileFailure) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(child: Text(state.message)),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// Displays the user's post count in a row.
class _PostCountRow extends StatelessWidget {
  const _PostCountRow({required this.postCount});

  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              '$postCount',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Posts',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
