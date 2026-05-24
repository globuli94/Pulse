// lib/features/auth/presentation/widgets/auth_header.dart
//
// AuthHeader — shared app icon + "Pulse" branding widget for auth screens.

import 'package:flutter/material.dart';

/// Displays the Pulse app icon and name prominently at the top of auth screens.
class AuthHeader extends StatelessWidget {
  /// Creates an [AuthHeader].
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/icon/pulse_icon.png',
            width: 80,
            height: 80,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pulse',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
