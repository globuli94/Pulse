// lib/features/posts/presentation/screens/create_post_screen.dart
//
// CreatePostScreen — form for composing and submitting a new post.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../bloc/create_post_bloc.dart';

/// Screen that allows the authenticated user to compose a new post.
class CreatePostScreen extends StatefulWidget {
  /// Creates a [CreatePostScreen].
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      context
          .read<CreatePostBloc>()
          .add(CreatePostImageSelected(image: image));
    }
  }

  void _removeImage() {
    context.read<CreatePostBloc>().add(const CreatePostImageRemoved());
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      context.read<CreatePostBloc>().add(
            CreatePostSubmitted(
              text: _textController.text.trim(),
              userId: authState.user.uid,
              displayName: authState.user.displayName,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreatePostBloc, CreatePostState>(
      listener: (context, state) {
        if (state is CreatePostSuccess) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        } else if (state is CreatePostFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('New Post')),
        body: BlocBuilder<CreatePostBloc, CreatePostState>(
          builder: (context, state) {
            final isSubmitting = state is CreatePostSubmitting;
            final attachedImage =
                state is CreatePostImageAttached ? state.image : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _textController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'What\'s on your mind?',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      minLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Post text is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (attachedImage != null) ...[
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(attachedImage.path),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isSubmitting ? null : _removeImage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: isSubmitting ? null : _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Add Photo'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton(
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Post'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
