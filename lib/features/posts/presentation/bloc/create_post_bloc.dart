// lib/features/posts/presentation/bloc/create_post_bloc.dart
//
// CreatePostBloc — manages the create post form state.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/repositories/posts_repository.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

/// BLoC responsible for the Create Post screen.
///
/// Screen-scoped: provided in the `/create-post` route builder, not in
/// `main.dart`.
class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  /// Creates a [CreatePostBloc].
  CreatePostBloc({required PostsRepository repository})
      : _repository = repository,
        super(const CreatePostInitial()) {
    on<CreatePostImageSelected>(_onImageSelected);
    on<CreatePostImageRemoved>(_onImageRemoved);
    on<CreatePostSubmitted>(_onSubmitted);
  }

  final PostsRepository _repository;

  void _onImageSelected(
    CreatePostImageSelected event,
    Emitter<CreatePostState> emit,
  ) {
    emit(CreatePostImageAttached(image: event.image));
  }

  void _onImageRemoved(
    CreatePostImageRemoved event,
    Emitter<CreatePostState> emit,
  ) {
    emit(const CreatePostInitial());
  }

  Future<void> _onSubmitted(
    CreatePostSubmitted event,
    Emitter<CreatePostState> emit,
  ) async {
    final image =
        state is CreatePostImageAttached ? (state as CreatePostImageAttached).image : null;

    emit(const CreatePostSubmitting());
    try {
      await _repository.createPost(
        text: event.text,
        userId: event.userId,
        image: image,
      );
      emit(const CreatePostSuccess());
    } catch (e) {
      emit(CreatePostFailure(error: e.toString()));
    }
  }
}
