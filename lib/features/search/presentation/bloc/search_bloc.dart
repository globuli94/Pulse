// lib/features/search/presentation/bloc/search_bloc.dart
//
// SearchBloc — manages user-search state with Timer-based debounce.

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/repositories/search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

/// BLoC that handles the user-search feature.
///
/// Debounces [SearchQueryChanged] events by 300 ms using a [Timer] so that
/// Firestore is not called on every keystroke.  No third-party concurrency
/// package is required.
///
/// The debounce is implemented by making [_onQueryChanged] synchronous: it
/// cancels any pending timer and starts a new 300 ms one.  When the timer
/// fires it dispatches the internal [_SearchDebounced] event, which is the
/// only handler that touches the repository.
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  /// Creates a [SearchBloc].
  SearchBloc({required SearchRepository repository})
      : _repository = repository,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<_SearchDebounced>(_onSearchDebounced);
  }

  final SearchRepository _repository;
  Timer? _debounce;

  void _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) {
    _debounce?.cancel();

    if (event.query.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => add(_SearchDebounced(query: event.query)),
    );
  }

  Future<void> _onSearchDebounced(
    _SearchDebounced event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());
    try {
      final users = await _repository.searchUsers(event.query);
      emit(SearchLoaded(users: users));
    } catch (e) {
      emit(SearchFailure(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
