// lib/features/profile/presentation/screens/user_profile_view_screen.dart
//
// UserProfileViewScreen — read-only profile view for any user via /profile/:uid.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/user_profile_bloc.dart';
import '../widgets/profile_avatar.dart';

/// Read-only profile view for any user, reachable at `/profile/:uid`.
///
/// [UserProfileBloc] is provided in the route builder (screen-scoped).
class UserProfileViewScreen extends StatelessWidget {
  /// Creates a [UserProfileViewScreen].
  const UserProfileViewScreen({super.key});

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
