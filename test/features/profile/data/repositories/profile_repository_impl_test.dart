import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/data/datasources/profile_firebase_data_source.dart';
import 'package:pulse/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/domain/exceptions/profile_exception.dart';

class MockProfileFirebaseDataSource extends Mock
    implements ProfileFirebaseDataSource {}

void main() {
  group('ProfileRepositoryImpl', () {
    late MockProfileFirebaseDataSource mockDataSource;
    late ProfileRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockProfileFirebaseDataSource();
      repository = ProfileRepositoryImpl(dataSource: mockDataSource);
    });

    group('getProfile', () {
      test('returns UserProfile when data source succeeds', () async {
        final userProfile = UserProfile(
          uid: 'test-uid',
          displayName: 'Test User',
          username: 'testuser',
          bio: 'Test bio',
          avatarUrl: 'https://example.com/avatar.jpg',
          followerCount: 10,
          followingCount: 5,
          postCount: 3,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(() => mockDataSource.getProfile('test-uid'))
            .thenAnswer((_) async => userProfile);

        final result = await repository.getProfile('test-uid');

        expect(result.uid, 'test-uid');
        expect(result.displayName, 'Test User');
        verify(() => mockDataSource.getProfile('test-uid')).called(1);
      });

      test('throws ProfileException when data source throws', () async {
        when(() => mockDataSource.getProfile('test-uid'))
            .thenThrow(ProfileException('User not found.'));

        expect(
          () => repository.getProfile('test-uid'),
          throwsA(isA<ProfileException>()),
        );
      });
    });

    group('updateProfile', () {
      test('delegates to data source and returns updated profile', () async {
        final updatedProfile = UserProfile(
          uid: 'test-uid',
          displayName: 'Updated Name',
          username: 'testuser',
          bio: 'Updated bio',
          avatarUrl: '',
          followerCount: 10,
          followingCount: 5,
          postCount: 3,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 3),
        );

        when(
          () => mockDataSource.updateProfile(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          ),
        ).thenAnswer((_) async => updatedProfile);

        final result = await repository.updateProfile(
          uid: 'test-uid',
          displayName: 'Updated Name',
          bio: 'Updated bio',
        );

        expect(result.displayName, 'Updated Name');
        verify(
          () => mockDataSource.updateProfile(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          ),
        ).called(1);
      });

      test('throws ProfileException when data source throws', () async {
        when(
          () => mockDataSource.updateProfile(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          ),
        ).thenThrow(ProfileException('Network error'));

        expect(
          () => repository.updateProfile(
            uid: 'test-uid',
            displayName: 'Updated Name',
            bio: 'Updated bio',
          ),
          throwsA(isA<ProfileException>()),
        );
      });
    });

    group('uploadAvatar', () {
      test('delegates to data source and returns updated profile', () async {
        final updatedProfile = UserProfile(
          uid: 'test-uid',
          displayName: 'Test User',
          username: 'testuser',
          bio: 'Test bio',
          avatarUrl: 'https://example.com/new-avatar.jpg',
          followerCount: 10,
          followingCount: 5,
          postCount: 3,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 2),
        );

        when(
          () => mockDataSource.uploadAvatar(
            uid: 'test-uid',
            imagePath: '/path/to/image.jpg',
          ),
        ).thenAnswer((_) async => updatedProfile);

        final result = await repository.uploadAvatar(
          uid: 'test-uid',
          imagePath: '/path/to/image.jpg',
        );

        expect(result.avatarUrl, 'https://example.com/new-avatar.jpg');
        verify(
          () => mockDataSource.uploadAvatar(
            uid: 'test-uid',
            imagePath: '/path/to/image.jpg',
          ),
        ).called(1);
      });

      test('throws ProfileException when upload fails', () async {
        when(
          () => mockDataSource.uploadAvatar(
            uid: 'test-uid',
            imagePath: '/path/to/image.jpg',
          ),
        ).thenThrow(ProfileException('Upload failed'));

        expect(
          () => repository.uploadAvatar(
            uid: 'test-uid',
            imagePath: '/path/to/image.jpg',
          ),
          throwsA(isA<ProfileException>()),
        );
      });
    });

    group('deleteAccount', () {
      test('delegates to data source', () async {
        when(
          () => mockDataSource.deleteAccount(uid: 'test-uid'),
        ).thenAnswer((_) async {});

        await repository.deleteAccount(uid: 'test-uid');

        verify(() => mockDataSource.deleteAccount(uid: 'test-uid')).called(1);
      });

      test('throws ProfileException when delete fails', () async {
        when(
          () => mockDataSource.deleteAccount(uid: 'test-uid'),
        ).thenThrow(ProfileException('Delete failed'));

        expect(
          () => repository.deleteAccount(uid: 'test-uid'),
          throwsA(isA<ProfileException>()),
        );
      });
    });
  });
}
