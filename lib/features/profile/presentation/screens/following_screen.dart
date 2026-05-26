// lib/features/profile/presentation/screens/following_screen.dart
//
// FollowingScreen — lists all users that a given user follows.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/following_bloc.dart';
import '../widgets/follow_user_tile.dart';

/// Screen that displays the users followed by the user with [viewedUid].
///
/// [FollowingBloc] is provided in the route builder — screen-scoped.
class FollowingScreen extends StatelessWidget {
  /// Creates a [FollowingScreen].
  const FollowingScreen({super.key, required this.viewedUid});

  /// The UID of the user whose following list is shown.
  final String viewedUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Following')),
      body: BlocBuilder<FollowingBloc, FollowingState>(
        builder: (context, state) {
          if (state is FollowingLoading || state is FollowingInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FollowingError) {
            return Center(child: Text(state.message));
          }
          if (state is FollowingLoaded) {
            if (state.following.isEmpty) {
              return const Center(child: Text('Not following anyone yet.'));
            }
            return ListView.builder(
              itemCount: state.following.length,
              itemBuilder: (context, index) =>
                  FollowUserTile(profile: state.following[index]),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
