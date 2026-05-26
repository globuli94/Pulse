// lib/features/profile/presentation/widgets/follow_user_tile.dart
//
// FollowUserTile — list tile for a single user in followers/following lists.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/user_profile.dart';
import 'profile_avatar.dart';

/// A list tile that displays a [UserProfile]'s avatar and display name.
///
/// Tapping the tile navigates to `/profile/:uid` for the given user.
class FollowUserTile extends StatelessWidget {
  /// Creates a [FollowUserTile].
  const FollowUserTile({super.key, required this.profile});

  /// The user profile to display.
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProfileAvatar(avatarUrl: profile.avatarUrl, radius: 22),
      title: Text(profile.displayName),
      onTap: () => context.push('/profile/${profile.uid}'),
    );
  }
}
