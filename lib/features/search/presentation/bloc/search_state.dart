// lib/features/search/presentation/bloc/search_state.dart
//
// SearchState — states for SearchBloc.

part of 'search_bloc.dart';

/// Base class for all [SearchBloc] states.
sealed class SearchState extends Equatable {
  const SearchState();
}

/// Initial state — query is empty, no results shown.
final class SearchInitial extends SearchState {
  const SearchInitial();

  @override
  List<Object?> get props => [];
}

/// A Firestore query is in flight.
final class SearchLoading extends SearchState {
  const SearchLoading();

  @override
  List<Object?> get props => [];
}

/// Firestore returned results (may be empty).
final class SearchLoaded extends SearchState {
  /// Creates a [SearchLoaded].
  const SearchLoaded({required this.users});

  /// The matched user profiles; may be empty.
  final List<UserProfile> users;

  @override
  List<Object?> get props => [users];
}

/// An error occurred while searching.
final class SearchFailure extends SearchState {
  /// Creates a [SearchFailure].
  const SearchFailure({required this.error});

  /// Human-readable error description.
  final String error;

  @override
  List<Object?> get props => [error];
}
