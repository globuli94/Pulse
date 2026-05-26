// lib/features/search/presentation/screens/search_screen.dart
//
// SearchScreen — full-screen user search with debounced Firestore queries.
//
// SearchBloc is screen-scoped: provided here rather than in main.dart because
// Search is not reachable from both a shell tab AND a named route.  The
// inner body widget (_SearchScreenBody) is the BLoC consumer so that the
// provider/consumer split rule is respected.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/search_repository.dart';
import '../bloc/search_bloc.dart';
import '../widgets/user_search_result_tile.dart';

/// Search tab screen — lets users search for other users by display name.
///
/// Provides its own [SearchBloc] (screen-scoped).  The body widget
/// [_SearchScreenBody] is the consumer; provider and consumer are separate
/// widgets.
class SearchScreen extends StatelessWidget {
  /// Creates a [SearchScreen].
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (context) => SearchBloc(
        repository: context.read<SearchRepository>(),
      ),
      child: const _SearchScreenBody(),
    );
  }
}

/// Inner body that consumes [SearchBloc].
class _SearchScreenBody extends StatefulWidget {
  const _SearchScreenBody();

  @override
  State<_SearchScreenBody> createState() => _SearchScreenBodyState();
}

class _SearchScreenBodyState extends State<_SearchScreenBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is Authenticated ? authState.user.uid : '';

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        context
                            .read<SearchBloc>()
                            .add(const SearchQueryChanged(query: ''));
                      },
                    );
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: (query) => context
                  .read<SearchBloc>()
                  .add(SearchQueryChanged(query: query)),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchInitial) {
                  return const Center(
                    child: Text('Search for users by name.'),
                  );
                }

                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchFailure) {
                  return const Center(
                    child: Text('Something went wrong.'),
                  );
                }

                if (state is SearchLoaded) {
                  if (state.users.isEmpty) {
                    return const Center(child: Text('No results found.'));
                  }
                  return ListView.builder(
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      return UserSearchResultTile(
                        key: ValueKey(user.uid),
                        user: user,
                        currentUserId: currentUserId,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
