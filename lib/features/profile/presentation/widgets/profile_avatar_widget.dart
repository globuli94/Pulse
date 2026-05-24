// lib/features/profile/presentation/widgets/profile_avatar_widget.dart
//
// ProfileAvatarWidget — circular avatar with optional camera overlay.

import 'package:flutter/material.dart';

/// Displays a circular avatar for a user profile.
///
/// When [onTap] is non-null, a camera overlay button is shown in the
/// bottom-right corner.
class ProfileAvatarWidget extends StatelessWidget {
  /// Creates a [ProfileAvatarWidget].
  const ProfileAvatarWidget({
    super.key,
    required this.avatarUrl,
    required this.radius,
    this.onTap,
  });

  /// The URL of the avatar image. Empty string shows a person icon placeholder.
  final String avatarUrl;

  /// The radius of the circular avatar.
  final double radius;

  /// Optional tap callback. When non-null, a camera overlay is shown.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl) as ImageProvider
              : null,
          child: avatarUrl.isEmpty
              ? Icon(Icons.person, size: radius)
              : null,
        ),
        if (onTap != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: CircleAvatar(
                radius: radius * 0.28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.camera_alt,
                  size: radius * 0.28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
