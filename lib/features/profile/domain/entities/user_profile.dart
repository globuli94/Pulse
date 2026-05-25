// lib/features/profile/domain/entities/user_profile.dart
//
// UserProfile — pure Dart domain entity for a user profile.

import 'package:equatable/equatable.dart';

/// Represents a user profile fetched from Firestore.
///
/// Contains no Firebase imports and is safe to use across all application
/// layers.
class UserProfile extends Equatable {
  /// Creates a [UserProfile].
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.postCount,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  /// Firebase Auth UID; mirrors the Firestore document ID.
  final String uid;

  /// Human-readable name shown in the UI.
  final String displayName;

  /// Short bio; may be empty string.
  final String bio;

  /// HTTPS URL of the avatar stored in Firebase Storage, or null if not set.
  final String? avatarUrl;

  /// Cached post count; default 0.
  final int postCount;

  /// Cached follower count; default 0.
  final int followerCount;

  /// Cached following count; default 0.
  final int followingCount;

  @override
  List<Object?> get props => [
        uid,
        displayName,
        bio,
        avatarUrl,
        postCount,
        followerCount,
        followingCount,
      ];
}
