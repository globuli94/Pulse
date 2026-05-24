import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pulse/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  group('AuthRepositoryImpl', () {
    late MockAuthRemoteDataSource mockDataSource;
    late AuthRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockAuthRemoteDataSource();
      repository = AuthRepositoryImpl(dataSource: mockDataSource);
    });

    test('signInWithEmail delegates to data source', () async {
      when(() => mockDataSource.signInWithEmail(any(), any()))
          .thenAnswer((_) async {});

      await repository.signInWithEmail('test@example.com', 'password123');

      verify(() => mockDataSource.signInWithEmail(
        'test@example.com',
        'password123',
      )).called(1);
    });

    test('signUpWithEmail delegates to data source', () async {
      when(() => mockDataSource.signUpWithEmail(any(), any()))
          .thenAnswer((_) async {});

      await repository.signUpWithEmail('newuser@example.com', 'password123');

      verify(() => mockDataSource.signUpWithEmail(
        'newuser@example.com',
        'password123',
      )).called(1);
    });

    test('signInWithGoogle delegates to data source', () async {
      when(() => mockDataSource.signInWithGoogle()).thenAnswer((_) async {});

      await repository.signInWithGoogle();

      verify(() => mockDataSource.signInWithGoogle()).called(1);
    });

    test('sendPasswordResetEmail delegates to data source', () async {
      when(() => mockDataSource.sendPasswordResetEmail(any()))
          .thenAnswer((_) async {});

      await repository.sendPasswordResetEmail('test@example.com');

      verify(() => mockDataSource.sendPasswordResetEmail(
        'test@example.com',
      )).called(1);
    });

    test('signOut delegates to data source', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockDataSource.signOut()).called(1);
    });

    test('authStateChanges returns a stream', () {
      when(() => mockDataSource.authStateChanges)
          .thenAnswer((_) => Stream<User?>.value(null));

      final result = repository.authStateChanges;

      expect(result, isA<Stream>());
      verify(() => mockDataSource.authStateChanges).called(1);
    });
  });
}
