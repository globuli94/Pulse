// lib/features/posts/presentation/bloc/create_post_state.dart
//
// CreatePostState — states for CreatePostBloc.

part of 'create_post_bloc.dart';

/// Base class for all CreatePostBloc states.
sealed class CreatePostState {
  const CreatePostState();
}

/// Initial state — no image selected, not submitting.
final class CreatePostInitial extends CreatePostState {
  const CreatePostInitial();
}

/// An image has been attached to the post.
final class CreatePostImageAttached extends CreatePostState {
  const CreatePostImageAttached({required this.image});

  final XFile image;
}

/// Post submission is in progress.
final class CreatePostSubmitting extends CreatePostState {
  const CreatePostSubmitting();
}

/// Post was created successfully.
final class CreatePostSuccess extends CreatePostState {
  const CreatePostSuccess();
}

/// Post creation failed.
final class CreatePostFailure extends CreatePostState {
  const CreatePostFailure({required this.error});

  final String error;
}
