// lib/features/notifications/presentation/screens/notifications_screen.dart
//
// NotificationsScreen — shows the current user's notifications.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notifications_bloc.dart';
import '../widgets/notification_tile.dart';

/// Screen that shows the list of in-app notifications for the current user.
///
/// [NotificationsBloc] is provided by the router builder or the shell screen —
/// this screen only consumes it.
///
/// Set [showAppBar] to `false` when embedding inside [ShellScreen] to avoid a
/// double AppBar — the shell already renders the global title bar.
class NotificationsScreen extends StatelessWidget {
  /// Creates a [NotificationsScreen].
  const NotificationsScreen({super.key, this.showAppBar = true});

  /// Whether to render the local [AppBar].
  ///
  /// Pass `false` when this screen is hosted inside [ShellScreen].
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsError) {
            return Center(child: Text(state.message));
          }
          if (state is NotificationsLoaded) {
            final notifications = state.notifications;
            if (notifications.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return NotificationTile(
                  key: ValueKey(n.id),
                  notification: n,
                  onTap: () => context.read<NotificationsBloc>().add(
                        NotificationMarkReadRequested(
                          notificationId: n.id,
                        ),
                      ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
