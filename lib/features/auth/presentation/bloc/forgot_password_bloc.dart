// lib/features/auth/presentation/bloc/forgot_password_bloc.dart
//
// ForgotPasswordBloc — handles password-reset email requests.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/exceptions/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

/// BLoC that manages the forgot-password form's loading, success, and error state.
class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  /// Creates a [ForgotPasswordBloc].
  ForgotPasswordBloc({required AuthRepository repository})
      : _repository = repository,
        super(const ForgotPasswordInitial()) {
    on<ForgotPasswordResetRequested>(_onResetRequested);
  }

  final AuthRepository _repository;

  Future<void> _onResetRequested(
    ForgotPasswordResetRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());
    try {
      await _repository.sendPasswordResetEmail(event.email);
      emit(const ForgotPasswordSuccess());
    } on AuthException catch (e) {
      emit(ForgotPasswordFailure(message: _messageFromCode(e.code)));
    } catch (_) {
      emit(const ForgotPasswordFailure(message: 'An unexpected error occurred.'));
    }
  }

  String _messageFromCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }
}
