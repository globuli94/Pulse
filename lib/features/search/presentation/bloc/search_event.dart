// lib/features/search/presentation/bloc/search_event.dart
//
// SearchEvent — events for SearchBloc.

part of 'search_bloc.dart';

/// Base class for all [SearchBloc] events.
sealed class SearchEvent extends Equatable {
  const SearchEvent();
}

/// Fired whenever the user changes the search query text.
final class SearchQueryChanged extends SearchEvent {
  /// Creates a [SearchQueryChanged].
  const SearchQueryChanged({required this.query});

  /// The current text entered in the search field.
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Internal event dispatched by the debounce [Timer].
///
/// Must not be created outside of [SearchBloc].
final class _SearchDebounced extends SearchEvent {
  const _SearchDebounced({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}
