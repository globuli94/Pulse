// lib/features/posts/presentation/bloc/like_event.dart
//
// LikeEvent — events for the per-item LikeBloc.

import 'package:equatable/equatable.dart';

sealed class LikeEvent extends Equatable {
  const LikeEvent();
  @override
  List<Object?> get props => [];
}

/// Initialise like state for [postId]. Fetches isLiked from Firestore.
final class LikeInitialised extends LikeEvent {
  const LikeInitialised({
    required this.postId,
    required this.userId,
    required this.initialLikeCount,
  });
  final String postId;
  final String userId;
  final int initialLikeCount;
  @override
  List<Object?> get props => [postId, userId, initialLikeCount];
}

/// Toggle like/unlike for [postId].
final class LikeToggleRequested extends LikeEvent {
  const LikeToggleRequested({
    required this.postId,
    required this.userId,
  });
  final String postId;
  final String userId;
  @override
  List<Object?> get props => [postId, userId];
}
