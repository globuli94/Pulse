// lib/features/profile/domain/entities/user_profile.dart
//
// UserProfile — pure Dart domain entity representing a user's public profile.

import 'package:equatable/equatable.dart';

/// Represents a user's public profile.
///
/// Pure Dart — zero Firebase imports.
class UserProfile extends Equatable {
  /// Creates a [UserProfile].
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.postCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The unique Firebase Auth user ID.
  final String uid;

  /// The user's display name.
  final String displayName;

  /// The user's unique handle (e.g. alice).
  final String username;

  /// The user's bio. Empty string if unset.
  final String bio;

  /// The user's avatar download URL. Empty string if unset.
  final String avatarUrl;

  /// The number of posts the user has created.
  final int postCount;

  /// When the profile was created.
  final DateTime createdAt;

  /// When the profile was last updated.
  final DateTime updatedAt;

  /// Returns a copy of this [UserProfile] with the given fields replaced.
  UserProfile copyWith({
    String? uid,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    int? postCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      postCount: postCount ?? this.postCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        username,
        bio,
        avatarUrl,
        postCount,
        createdAt,
        updatedAt,
      ];
}
