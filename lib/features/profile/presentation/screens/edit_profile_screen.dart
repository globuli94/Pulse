// lib/features/profile/presentation/screens/edit_profile_screen.dart
//
// EditProfileScreen — lets the authenticated user edit their profile.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_avatar.dart';

/// Screen for editing the authenticated user's display name, bio, and avatar.
///
/// Route: `/edit-profile`
/// Reads and dispatches to the global [ProfileBloc].
class EditProfileScreen extends StatefulWidget {
  /// Creates an [EditProfileScreen].
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  String? _selectedAvatarPath;
  String? _currentAvatarUrl;
  bool _initialized = false;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final state = context.read<ProfileBloc>().state;
      final profile = switch (state) {
        ProfileLoaded(:final profile) => profile,
        ProfileUpdating(:final profile) => profile,
        ProfileUpdateSuccess(:final profile) => profile,
        _ => null,
      };
      _displayNameController =
          TextEditingController(text: profile?.displayName ?? '');
      _bioController = TextEditingController(text: profile?.bio ?? '');
      _currentAvatarUrl = profile?.avatarUrl;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxFileSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image must be smaller than 5 MB.'),
          ),
        );
      }
      return;
    }

    setState(() => _selectedAvatarPath = picked.path);
  }

  void _save(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            uid: authState.user.uid,
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim(),
            avatarFilePath: _selectedAvatarPath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          context.pop();
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final isUpdating = state is ProfileUpdating;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Profile'),
              leading: BackButton(onPressed: () => context.pop()),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ProfileAvatar(
                      avatarUrl: _selectedAvatarPath != null
                          ? null
                          : _currentAvatarUrl,
                      radius: 50,
                      onTap: isUpdating ? null : _pickAvatar,
                    ),
                    if (_selectedAvatarPath != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'New photo selected',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextField(
                      controller: _displayNameController,
                      enabled: !isUpdating,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      enabled: !isUpdating,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    isUpdating
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => _save(context),
                            child: const Text('Save'),
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
