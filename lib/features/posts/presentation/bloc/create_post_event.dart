// lib/features/posts/presentation/bloc/create_post_event.dart
//
// CreatePostEvent — events for CreatePostBloc.

part of 'create_post_bloc.dart';

/// Base class for all CreatePostBloc events.
sealed class CreatePostEvent {
  const CreatePostEvent();
}

/// An image has been selected from the picker.
final class CreatePostImageSelected extends CreatePostEvent {
  const CreatePostImageSelected({required this.image});

  final XFile image;
}

/// The selected image has been removed.
final class CreatePostImageRemoved extends CreatePostEvent {
  const CreatePostImageRemoved();
}

/// The form has been submitted.
final class CreatePostSubmitted extends CreatePostEvent {
  const CreatePostSubmitted({
    required this.text,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String text;
  final String userId;
  final String displayName;
  final String? avatarUrl;
}
