// lib/features/profile/presentation/widgets/profile_avatar.dart
//
// ProfileAvatar — reusable circular avatar widget.

import 'package:flutter/material.dart';

/// Displays a circular avatar.
///
/// Shows a [NetworkImage] when [avatarUrl] is non-null, otherwise falls back
/// to an [Icons.person] placeholder icon.
class ProfileAvatar extends StatelessWidget {
  /// Creates a [ProfileAvatar].
  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.radius,
    this.onTap,
  });

  /// The HTTPS URL of the avatar image, or null to show the placeholder.
  final String? avatarUrl;

  /// The radius of the [CircleAvatar].
  final double radius;

  /// Optional tap callback; wraps the avatar in a [GestureDetector] when set.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundImage:
          avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Icon(Icons.person, size: radius)
          : null,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
