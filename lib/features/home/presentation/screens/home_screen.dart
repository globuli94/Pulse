// lib/features/home/presentation/screens/home_screen.dart
//
// HomeScreen — placeholder home screen shown to authenticated users.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Placeholder home screen displayed after successful authentication.
///
/// Shows a welcome message and provides a log-out action.
class HomeScreen extends StatelessWidget {
  /// Creates a [HomeScreen].
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignedOut()),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to Pulse'),
      ),
    );
  }
}
