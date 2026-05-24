// lib/features/feed/presentation/screens/feed_screen.dart
//
// FeedScreen — live post feed using PostsFeedBloc.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/posts/presentation/bloc/posts_feed_bloc.dart';
import '../../../../features/posts/presentation/widgets/post_card.dart';

/// Main feed screen showing all posts in reverse-chronological order.
///
/// Consumes the globally-provided [PostsFeedBloc] — does NOT create its own
/// [BlocProvider] wrapper.
class FeedScreen extends StatefulWidget {
  /// Creates a [FeedScreen].
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<PostsFeedBloc>();
    if (bloc.state is PostsFeedInitial) {
      bloc.add(const PostsFeedSubscriptionRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-post'),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<PostsFeedBloc, PostsFeedState>(
        builder: (context, state) {
          if (state is PostsFeedLoading || state is PostsFeedInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostsFeedError) {
            return Center(child: Text(state.error));
          }

          if (state is PostsFeedLoaded) {
            if (state.posts.isEmpty) {
              return const Center(child: Text('No posts yet'));
            }
            return ListView.builder(
              itemCount: state.posts.length,
              itemBuilder: (context, index) =>
                  PostCard(post: state.posts[index]),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
