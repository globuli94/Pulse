// lib/features/profile/presentation/widgets/profile_avatar_widget.dart
//
// ProfileAvatarWidget — circular avatar with optional camera overlay.

import 'package:flutter/material.dart';

/// Displays a circular avatar for a user profile.
///
/// When [onTap] or [onCameraPressed] is non-null, a camera overlay button is
/// shown in the bottom-right corner.
class ProfileAvatarWidget extends StatelessWidget {
  /// Creates a [ProfileAvatarWidget].
  const ProfileAvatarWidget({
    super.key,
    this.avatarUrl,
    this.radius = 40,
    this.onTap,
    this.onCameraPressed,
  });

  /// The URL of the avatar image. Null or empty string shows a person icon.
  final String? avatarUrl;

  /// The radius of the circular avatar. Defaults to 40.
  final double radius;

  /// Optional tap callback. When non-null, a camera overlay is shown.
  final VoidCallback? onTap;

  /// Optional camera button callback. When non-null, a camera overlay is shown.
  final VoidCallback? onCameraPressed;

  @override
  Widget build(BuildContext context) {
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;
    final cameraCallback = onCameraPressed ?? onTap;
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage: hasUrl
              ? NetworkImage(avatarUrl!) as ImageProvider
              : null,
          child: !hasUrl
              ? Icon(Icons.person, size: radius)
              : null,
        ),
        if (cameraCallback != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: cameraCallback,
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
