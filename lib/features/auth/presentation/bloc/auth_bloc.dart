// lib/features/auth/presentation/bloc/auth_bloc.dart
//
// AuthBloc — manages the global authentication state stream.

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC responsible for tracking the global authentication state.
///
/// On [AuthStarted], subscribes to [AuthRepository.authStateChanges] and
/// emits [Authenticated] or [Unauthenticated] whenever the stream changes.
/// On [AuthSignedOut], calls [AuthRepository.signOut]; the stream update
/// automatically drives the state transition.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Creates an [AuthBloc].
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onAuthStarted);
    on<AuthSignedOut>(_onAuthSignedOut);
    on<_AuthUserChanged>(_onAuthUserChanged);
  }

  final AuthRepository _repository;
  StreamSubscription<AppUser?>? _authStateSubscription;

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) {
    _authStateSubscription?.cancel();
    _authStateSubscription = _repository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  void _onAuthUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    final user = event.user;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.signOut();
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
