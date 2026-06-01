// lib/features/feed/presentation/screens/feed_screen.dart
//
// FeedScreen — paginated post feed using PostsFeedBloc.

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<PostsFeedBloc>();
    if (bloc.state is PostsFeedInitial) {
      bloc.add(const PostsFeedSubscriptionRequested());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostsFeedBloc>().add(const PostsFeedNextPageRequested());
    }
  }

  Future<void> _onRefresh() async {
    context.read<PostsFeedBloc>().add(const PostsFeedSubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
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
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: state.posts.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(top: kToolbarHeight),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Center(
                          heightFactor: 8,
                          child: Text('No posts yet'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: kToolbarHeight),
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Extra slot for bottom loading indicator.
                      itemCount:
                          state.posts.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.posts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return PostCard(post: state.posts[index]);
                      },
                    ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
