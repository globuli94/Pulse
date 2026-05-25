// lib/features/home/presentation/screens/shell_screen.dart
//
// ShellScreen — main navigation shell with a bottom navigation bar.

import 'package:flutter/material.dart';

import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

/// Root navigation shell shown to authenticated users.
///
/// Renders an [IndexedStack] of feature screens and a [BottomNavigationBar]
/// with Feed and Profile tabs. Navigation state is preserved across tab
/// switches because [IndexedStack] keeps all children alive.
class ShellScreen extends StatefulWidget {
  /// Creates a [ShellScreen].
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // SearchScreen provides its own SearchBloc and is included in the stack
    // only when the Search tab is active.  This keeps Feed and Profile state
    // alive across tab switches while avoiding eager BLoC creation for Search.
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const FeedScreen(),
          if (_currentIndex == 1)
            const SearchScreen()
          else
            const SizedBox.shrink(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
