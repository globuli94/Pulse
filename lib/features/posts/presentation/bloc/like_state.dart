// lib/features/posts/presentation/bloc/like_state.dart
//
// LikeState — states for the per-item LikeBloc.

import 'package:equatable/equatable.dart';

sealed class LikeState extends Equatable {
  const LikeState();
  @override
  List<Object?> get props => [];
}

final class LikeInitial extends LikeState {
  const LikeInitial();
}

final class LikeLoading extends LikeState {
  const LikeLoading();
}

final class LikeLoaded extends LikeState {
  const LikeLoaded({required this.isLiked, required this.likeCount});
  final bool isLiked;
  final int likeCount;
  @override
  List<Object?> get props => [isLiked, likeCount];
}

final class LikeError extends LikeState {
  const LikeError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}
