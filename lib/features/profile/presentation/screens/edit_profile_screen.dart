// lib/features/profile/presentation/screens/edit_profile_screen.dart
//
// EditProfileScreen — allows a user to edit their display name and bio.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile_bloc.dart';

/// Screen that allows the signed-in user to edit their display name and bio.
class EditProfileScreen extends StatefulWidget {
  /// Creates an [EditProfileScreen].
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _saveInProgress = false;
  String? _displayNameError;

  @override
  void initState() {
    super.initState();
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded) {
      _displayNameController.text = profileState.profile.displayName;
      _bioController.text = profileState.profile.bio;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_displayNameController.text.isEmpty) {
      setState(() => _displayNameError = 'Display name cannot be empty');
      return;
    }
    setState(() {
      _saveInProgress = true;
      _displayNameError = null;
    });
    final state = context.read<ProfileBloc>().state;
    final uid = state is ProfileLoaded ? state.profile.uid : '';
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            uid: uid,
            displayName: _displayNameController.text,
            bio: _bioController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && _saveInProgress) {
          Navigator.pop(context);
        } else if (state is ProfileFailure) {
          setState(() => _saveInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileUpdating) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileLoaded && !_saveInProgress) {
          _displayNameController.text = state.profile.displayName;
          _bioController.text = state.profile.bio;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Edit Profile'),
            leading: const BackButton(),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    errorText: _displayNameError,
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLength: 200,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _onSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
