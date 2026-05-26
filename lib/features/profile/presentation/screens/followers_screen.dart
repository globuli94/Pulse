// lib/features/profile/presentation/screens/followers_screen.dart
//
// FollowersScreen — lists all followers of a given user.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/followers_bloc.dart';
import '../widgets/follow_user_tile.dart';

/// Screen that displays the followers of the user with [viewedUid].
///
/// [FollowersBloc] is provided in the route builder — screen-scoped.
class FollowersScreen extends StatelessWidget {
  /// Creates a [FollowersScreen].
  const FollowersScreen({super.key, required this.viewedUid});

  /// The UID of the user whose followers are shown.
  final String viewedUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: BlocBuilder<FollowersBloc, FollowersState>(
        builder: (context, state) {
          if (state is FollowersLoading || state is FollowersInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FollowersError) {
            return Center(child: Text(state.message));
          }
          if (state is FollowersLoaded) {
            if (state.followers.isEmpty) {
              return const Center(child: Text('No followers yet.'));
            }
            return ListView.builder(
              itemCount: state.followers.length,
              itemBuilder: (context, index) =>
                  FollowUserTile(profile: state.followers[index]),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
