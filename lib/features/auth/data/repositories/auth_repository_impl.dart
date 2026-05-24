// lib/features/auth/data/repositories/auth_repository_impl.dart
//
// AuthRepositoryImpl — implements AuthRepository using AuthRemoteDataSource.

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Concrete implementation of [AuthRepository].
///
/// Maps Firebase [User] objects to the domain [AppUser] entity, keeping the
/// domain layer free of Firebase imports.
class AuthRepositoryImpl implements AuthRepository {
  /// Creates an [AuthRepositoryImpl].
  const AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final AuthRemoteDataSource _dataSource;

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.map(
      (user) => user == null
          ? null
          : AppUser(
              uid: user.uid,
              email: user.email,
              displayName: user.displayName ?? '',
            ),
    );
  }

  @override
  Future<void> signUpWithEmail(String email, String password) =>
      _dataSource.signUpWithEmail(email, password);

  @override
  Future<void> signInWithEmail(String email, String password) =>
      _dataSource.signInWithEmail(email, password);

  @override
  Future<void> signInWithGoogle() => _dataSource.signInWithGoogle();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _dataSource.sendPasswordResetEmail(email);

  @override
  Future<void> signOut() => _dataSource.signOut();
}
