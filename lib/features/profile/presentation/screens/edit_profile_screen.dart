// lib/features/profile/presentation/screens/edit_profile_screen.dart
//
// EditProfileScreen — allows a user to edit their display name and bio.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_profile.dart';
import '../bloc/profile_bloc.dart';

/// Screen that allows the signed-in user to edit their display name and bio.
class EditProfileScreen extends StatefulWidget {
  /// Creates an [EditProfileScreen].
  const EditProfileScreen({super.key, required this.profile});

  /// The current profile, used to pre-fill the form fields.
  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late String _displayName;
  late String _bio;
  bool _saveInProgress = false;

  @override
  void initState() {
    super.initState();
    _displayName = widget.profile.displayName;
    _bio = widget.profile.bio;
  }

  void _onSave() {
    setState(() => _saveInProgress = true);
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(
            uid: widget.profile.uid,
            displayName: _displayName,
            bio: _bio,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && _saveInProgress) {
          Navigator.pop(context);
        } else if (state is ProfileFailure) {
          setState(() => _saveInProgress = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: const BackButton(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                initialValue: widget.profile.displayName,
                decoration:
                    const InputDecoration(labelText: 'Display Name'),
                maxLength: 50,
                onChanged: (v) => _displayName = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: widget.profile.bio,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLength: 200,
                maxLines: 3,
                onChanged: (v) => _bio = v,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
