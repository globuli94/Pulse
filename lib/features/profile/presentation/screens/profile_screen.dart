// lib/features/profile/presentation/screens/profile_screen.dart
//
// ProfileScreen — own-profile tab screen.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_avatar_widget.dart';
import 'edit_profile_screen.dart';

/// Displays the currently signed-in user's profile.
class ProfileScreen extends StatefulWidget {
  /// Creates a [ProfileScreen].
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch initial load after the first frame so context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<ProfileBloc>().state is! ProfileInitial) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context
            .read<ProfileBloc>()
            .add(ProfileLoadRequested(uid: authState.user.uid));
      }
    });
  }

  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    String uid,
  ) async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xFile == null) return;
    if (!context.mounted) return;
    context.read<ProfileBloc>().add(
          AvatarUploadRequested(
            uid: uid,
            imagePath: xFile.path,
          ),
        );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    String uid,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'All your data will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ProfileBloc>().add(AccountDeleteRequested(uid: uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileLoaded ||
            (state is ProfileUpdating && state.profile != null)) {
          final profile = state is ProfileLoaded
              ? state.profile
              : (state as ProfileUpdating).profile!;

          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Column(
              children: [
                if (state is ProfileUpdating && state.profile != null)
                  const LinearProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ProfileAvatarWidget(
                          avatarUrl: profile.avatarUrl,
                          radius: 50,
                          onTap: () =>
                              _pickAndUploadAvatar(context, profile.uid),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium,
                        ),
                        Text(
                          '@${profile.username}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary,
                              ),
                        ),
                        if (profile.bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            profile.bio,
                            style:
                                Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _PostCountRow(postCount: profile.postCount),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => BlocProvider.value(
                                value: context.read<ProfileBloc>(),
                                child: const EditProfileScreen(),
                              ),
                            ),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Log Out'),
                          onTap: () => context
                              .read<AuthBloc>()
                              .add(const AuthSignedOut()),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever,
                            color:
                                Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            'Delete Account',
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onTap: () =>
                              _confirmDeleteAccount(context, profile.uid),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is ProfileFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(child: Text(state.message)),
          );
        }

        // ProfileInitial, AccountDeleteSuccess
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

/// Displays the user's post count in a row.
class _PostCountRow extends StatelessWidget {
  const _PostCountRow({required this.postCount});

  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              '$postCount',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Posts',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
