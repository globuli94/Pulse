// lib/features/home/presentation/screens/shell_screen.dart
//
// ShellScreen — main navigation shell with a bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../chat/presentation/bloc/unread_count_cubit.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';

/// Root navigation shell shown to authenticated users.
///
/// Renders an [IndexedStack] of feature screens and a [BottomNavigationBar]
/// with Feed, Search, Messages, and Profile tabs. Navigation state is
/// preserved across tab switches because [IndexedStack] keeps all children
/// alive (except Search which is conditionally rendered to avoid eager BLoC
/// creation).
///
/// The Messages tab shows an unread count badge sourced from the global
/// [UnreadCountCubit] registered in main.dart.
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const FeedScreen(),
          if (_currentIndex == 1)
            const SearchScreen()
          else
            const SizedBox.shrink(),
          const ConversationsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BlocBuilder<UnreadCountCubit, int>(
        builder: (context, unreadCount) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Feed',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: _ChatTabIcon(unreadCount: unreadCount, active: false),
                activeIcon: _ChatTabIcon(unreadCount: unreadCount, active: true),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Chat tab icon with an optional unread count badge.
class _ChatTabIcon extends StatelessWidget {
  const _ChatTabIcon({required this.unreadCount, required this.active});

  final int unreadCount;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(active ? Icons.chat : Icons.chat_outlined);
    if (unreadCount <= 0) return icon;

    return Badge(
      label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
      child: icon,
    );
  }
}
