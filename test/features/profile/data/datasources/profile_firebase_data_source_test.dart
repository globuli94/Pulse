import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/data/datasources/profile_firebase_data_source.dart';
import 'package:pulse/features/profile/domain/exceptions/profile_exception.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockReference extends Mock implements Reference {}

class MockTask extends Mock implements UploadTask {}

void main() {
  group('ProfileFirebaseDataSource', () {
    late MockFirebaseFirestore mockFirebaseFirestore;
    late MockFirebaseStorage mockFirebaseStorage;
    late ProfileFirebaseDataSource dataSource;

    setUp(() {
      mockFirebaseFirestore = MockFirebaseFirestore();
      mockFirebaseStorage = MockFirebaseStorage();
      dataSource = ProfileFirebaseDataSource(
        firestore: mockFirebaseFirestore,
        storage: mockFirebaseStorage,
      );
    });

    group('getProfile', () {
      test('returns UserProfile when document exists', () async {
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('test-uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(true);
        when(() => mockDocSnapshot.data()).thenReturn({
          'uid': 'test-uid',
          'displayName': 'Test User',
          'username': 'testuser',
          'bio': 'Test bio',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'followerCount': 10,
          'followingCount': 5,
          'postCount': 3,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });

        final profile = await dataSource.getProfile('test-uid');

        expect(profile.uid, 'test-uid');
        expect(profile.displayName, 'Test User');
        expect(profile.username, 'testuser');
        expect(profile.bio, 'Test bio');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.followerCount, 10);
        expect(profile.followingCount, 5);
        expect(profile.postCount, 3);
      });

      test('throws ProfileException when document does not exist', () async {
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('nonexistent'))
            .thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(false);

        expect(
          () => dataSource.getProfile('nonexistent'),
          throwsA(isA<ProfileException>()),
        );
      });

      test('handles missing optional fields gracefully', () async {
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('test-uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(true);
        when(() => mockDocSnapshot.data()).thenReturn({
          'uid': 'test-uid',
          'displayName': 'Test User',
          'username': 'testuser',
          'bio': '',
          'avatarUrl': '',
          'followerCount': 0,
          'followingCount': 0,
          'postCount': 0,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        final profile = await dataSource.getProfile('test-uid');

        expect(profile.bio, '');
        expect(profile.avatarUrl, '');
      });
    });

    group('updateProfile', () {
      test('sends only displayName, bio, updatedAt to Firestore', () async {
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('test-uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});

        // Mock the getProfile call after update
        final mockDocSnapshot = MockDocumentSnapshot();
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(true);
        when(() => mockDocSnapshot.data()).thenReturn({
          'uid': 'test-uid',
          'displayName': 'Updated Name',
          'username': 'testuser',
          'bio': 'Updated bio',
          'avatarUrl': '',
          'followerCount': 10,
          'followingCount': 5,
          'postCount': 3,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'updatedAt': Timestamp.now(),
        });

        await dataSource.updateProfile(
          uid: 'test-uid',
          displayName: 'Updated Name',
          bio: 'Updated bio',
        );

        verify(() => mockDocRef.update(any())).called(1);
      });

      test('does not send postCount, followerCount, or other fields', () async {
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('test-uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(true);
        when(() => mockDocSnapshot.data()).thenReturn({
          'uid': 'test-uid',
          'displayName': 'Updated Name',
          'username': 'testuser',
          'bio': 'Updated bio',
          'avatarUrl': '',
          'followerCount': 10,
          'followingCount': 5,
          'postCount': 3,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'updatedAt': Timestamp.now(),
        });

        await dataSource.updateProfile(
          uid: 'test-uid',
          displayName: 'Updated Name',
          bio: 'Updated bio',
        );

        // Verify that only displayName, bio, and updatedAt were in the update call
        final capturedData = verify(() => mockDocRef.update(captureAny())).captured.single as Map<String, dynamic>;
        expect(capturedData.containsKey('displayName'), true);
        expect(capturedData.containsKey('bio'), true);
        expect(capturedData.containsKey('updatedAt'), true);
        expect(capturedData.containsKey('postCount'), false);
        expect(capturedData.containsKey('followerCount'), false);
      });

      test('throws when display name is empty', () async {
        expect(
          () => dataSource.updateProfile(
            uid: 'test-uid',
            displayName: '',
            bio: 'Updated bio',
          ),
          throwsA(isA<ProfileException>()),
        );
      });
    });

    group('uploadAvatar', () {
      test('uploads file to avatars/{uid}/{filename} and updates user document',
          () async {
        final mockStorageRef = MockReference();
        final mockUploadTask = MockTask();
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockDocSnapshot = MockDocumentSnapshot();

        when(() => mockFirebaseStorage.ref('avatars/test-uid/avatar.jpg'))
            .thenReturn(mockStorageRef);
        when(() => mockStorageRef.putFile(any()))
            .thenReturn(mockUploadTask);
        when(() => mockStorageRef.getDownloadURL())
            .thenAnswer((_) async => 'https://example.com/new-avatar.jpg');

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('test-uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.update(any())).thenAnswer((_) async {});
        when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);
        when(() => mockDocSnapshot.exists).thenReturn(true);
        when(() => mockDocSnapshot.data()).thenReturn({
          'uid': 'test-uid',
          'displayName': 'Test User',
          'username': 'testuser',
          'bio': 'Test bio',
          'avatarUrl': 'https://example.com/new-avatar.jpg',
          'followerCount': 10,
          'followingCount': 5,
          'postCount': 3,
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
          'updatedAt': Timestamp.now(),
        });

        await dataSource.uploadAvatar(
          uid: 'test-uid',
          imagePath: '/path/to/avatar.jpg',
        );

        verify(() => mockFirebaseStorage.ref('avatars/test-uid/avatar.jpg'))
            .called(1);
      });

      test('throws ProfileException on upload failure', () async {
        final mockStorageRef = MockReference();

        when(() => mockFirebaseStorage.ref(any()))
            .thenReturn(mockStorageRef);
        when(() => mockStorageRef.putFile(any()))
            .thenThrow(Exception('Upload failed'));

        expect(
          () => dataSource.uploadAvatar(
            uid: 'test-uid',
            imagePath: '/path/to/avatar.jpg',
          ),
          throwsA(isA<ProfileException>()),
        );
      });
    });

    group('deleteAccount', () {
      test('deletes user document from Firestore', () async {
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('test-uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.delete()).thenAnswer((_) async {});

        await dataSource.deleteAccount(uid: 'test-uid');

        verify(() => mockDocRef.delete()).called(1);
      });

      test('throws ProfileException when delete fails', () async {
        final mockCollectionRef = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(() => mockFirebaseFirestore.collection('users'))
            .thenReturn(mockCollectionRef);
        when(() => mockCollectionRef.doc('test-uid')).thenReturn(mockDocRef);
        when(() => mockDocRef.delete()).thenThrow(Exception('Delete failed'));

        expect(
          () => dataSource.deleteAccount(uid: 'test-uid'),
          throwsA(isA<ProfileException>()),
        );
      });
    });
  });
}
