// lib/features/home/presentation/screens/shell_screen.dart
//
// ShellScreen — main navigation shell with a bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../chat/presentation/bloc/unread_count_cubit.dart';
import '../../../chat/presentation/screens/conversations_screen.dart';
import '../../../feed/presentation/screens/feed_screen.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../../notifications/presentation/bloc/notifications_bloc.dart';
import '../../../notifications/presentation/bloc/unread_notifications_count_cubit.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../bloc/shell_tab_cubit.dart';

/// Root navigation shell shown to authenticated users.
///
/// Renders an [IndexedStack] of feature screens and a [BottomNavigationBar]
/// with Feed, Search, Messages, Notifications, and Profile tabs. Navigation
/// state is preserved across tab switches because [IndexedStack] keeps all
/// children alive (except Search and Notifications which are conditionally
/// rendered to avoid eager BLoC creation).
///
/// The Messages tab shows an unread count badge sourced from the global
/// [UnreadCountCubit] registered in main.dart.
///
/// The Notifications tab shows an unread count badge sourced from the global
/// [UnreadNotificationsCountCubit] registered in main.dart.
///
/// The bell icon in the AppBar shows the same unread notification count and
/// remains unchanged.
///
/// Active tab index is owned by the global [ShellTabCubit] so that other
/// widgets (e.g. [PostCard]) can programmatically switch tabs.
class ShellScreen extends StatelessWidget {
  /// Creates a [ShellScreen].
  const ShellScreen({super.key});

  static const _tabTitles = [
    'Feed',
    'Search',
    'Messages',
    'Notifications',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellTabCubit, int>(
      builder: (context, currentIndex) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _tabTitles[currentIndex],
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: const [_NotificationBellButton()],
          ),
          body: IndexedStack(
            index: currentIndex,
            children: [
              const FeedScreen(),
              if (currentIndex == 1)
                const SearchScreen()
              else
                const SizedBox.shrink(),
              const ConversationsScreen(),
              if (currentIndex == 3)
                BlocProvider<NotificationsBloc>(
                  create: (context) {
                    final authState = context.read<AuthBloc>().state;
                    final uid =
                        authState is Authenticated ? authState.user.uid : '';
                    return NotificationsBloc(
                      repository: context.read<NotificationsRepository>(),
                    )..add(NotificationsSubscriptionRequested(userId: uid));
                  },
                  child: const NotificationsScreen(showAppBar: false),
                )
              else
                const SizedBox.shrink(),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BlocBuilder<UnreadCountCubit, int>(
            builder: (context, chatUnreadCount) {
              return BlocBuilder<UnreadNotificationsCountCubit, int>(
                builder: (context, notifUnreadCount) {
                  return BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    currentIndex: currentIndex,
                    onTap: (index) =>
                        context.read<ShellTabCubit>().switchToTab(index),
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
                        icon: _TabBadgeIcon(
                          unreadCount: chatUnreadCount,
                          icon: Icons.chat_outlined,
                        ),
                        activeIcon: _TabBadgeIcon(
                          unreadCount: chatUnreadCount,
                          icon: Icons.chat,
                        ),
                        label: 'Messages',
                      ),
                      BottomNavigationBarItem(
                        icon: _TabBadgeIcon(
                          unreadCount: notifUnreadCount,
                          icon: Icons.notifications_outlined,
                        ),
                        activeIcon: _TabBadgeIcon(
                          unreadCount: notifUnreadCount,
                          icon: Icons.notifications,
                        ),
                        label: 'Notifications',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person_outlined),
                        activeIcon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Bell icon button in the AppBar that shows the unread notification count.
class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnreadNotificationsCountCubit, int>(
      builder: (context, unreadCount) {
        final icon = IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => context.push('/notifications'),
        );
        if (unreadCount <= 0) return icon;
        return Badge(
          backgroundColor: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
          child: icon,
        );
      },
    );
  }
}

/// Tab icon with an optional unread count [Badge].
///
/// Shows a count label when [unreadCount] > 0, and no badge when the count is
/// zero. Uses Flutter's built-in Material 3 [Badge] widget for consistency with
/// the AppBar bell indicator in [_NotificationBellButton].
class _TabBadgeIcon extends StatelessWidget {
  const _TabBadgeIcon({required this.unreadCount, required this.icon});

  final int unreadCount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (unreadCount <= 0) return iconWidget;
    return Badge(
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Theme.of(context).colorScheme.onPrimary,
      label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
      child: iconWidget,
    );
  }
}
