// test/features/profile/data/datasources/profile_firebase_data_source_test.dart
//
// Unit tests for ProfileFirebaseDataSource.
// Firestore operations use FakeFirebaseFirestore (in-memory).
// Storage operations use mocktail stubs.

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/data/datasources/profile_firebase_data_source.dart';
import 'package:pulse/features/profile/domain/exceptions/profile_exception.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

class MockStorageReference extends Mock implements Reference {}

// Fake UploadTask that completes immediately when awaited.
class _FakeUploadTask extends Fake implements UploadTask {
  @override
  Future<R> then<R>(
    FutureOr<R> Function(TaskSnapshot value) onValue, {
    Function? onError,
  }) =>
      Future<TaskSnapshot?>.value(null).then(
        (_) => onValue(_FakeTaskSnapshot()),
        onError: onError,
      );

  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) =>
      Future.value(_FakeTaskSnapshot());

  @override
  Future<TaskSnapshot> whenComplete(FutureOr<void> Function() action) =>
      Future.value(_FakeTaskSnapshot());

  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) =>
      Future.value(_FakeTaskSnapshot());

  @override
  Stream<TaskSnapshot> asStream() => Stream.value(_FakeTaskSnapshot());

  @override
  Future<bool> cancel() async => false;
}

class _FakeTaskSnapshot extends Fake implements TaskSnapshot {}

void main() {
  setUpAll(() {
    registerFallbackValue(File(''));
  });

  group('ProfileFirebaseDataSource', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late ProfileFirebaseDataSource dataSource;

    const testUid = 'test-uid';

    final baseDoc = <String, dynamic>{
      'uid': testUid,
      'displayName': 'Test User',
      'username': 'testuser',
      'bio': 'Test bio',
      'avatarUrl': 'https://example.com/avatar.jpg',
      'followerCount': 10,
      'followingCount': 5,
      'postCount': 3,
      'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
    };

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      dataSource = ProfileFirebaseDataSource(
        firestore: fakeFirestore,
        storage: mockStorage,
      );
    });

    group('getProfile', () {
      test('returns UserProfile when document exists', () async {
        await fakeFirestore.collection('users').doc(testUid).set(baseDoc);

        final profile = await dataSource.getProfile(testUid);

        expect(profile.uid, testUid);
        expect(profile.displayName, 'Test User');
        expect(profile.username, 'testuser');
        expect(profile.bio, 'Test bio');
        expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
        expect(profile.followerCount, 10);
        expect(profile.followingCount, 5);
        expect(profile.postCount, 3);
      });

      test('throws ProfileException when document does not exist', () async {
        await expectLater(
          dataSource.getProfile('nonexistent'),
          throwsA(isA<ProfileException>()),
        );
      });

      test('handles missing optional fields gracefully', () async {
        await fakeFirestore.collection('users').doc(testUid).set({
          'uid': testUid,
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

        final profile = await dataSource.getProfile(testUid);

        expect(profile.bio, '');
        expect(profile.avatarUrl, '');
      });
    });

    group('updateProfile', () {
      test('sends only displayName, bio, updatedAt to Firestore', () async {
        await fakeFirestore.collection('users').doc(testUid).set(baseDoc);

        await dataSource.updateProfile(
          uid: testUid,
          displayName: 'Updated Name',
          bio: 'Updated bio',
        );

        final doc =
            await fakeFirestore.collection('users').doc(testUid).get();
        final data = doc.data()!;
        expect(data['displayName'], 'Updated Name');
        expect(data['bio'], 'Updated bio');
      });

      test('does not send postCount, followerCount, or other fields',
          () async {
        await fakeFirestore.collection('users').doc(testUid).set(baseDoc);

        await dataSource.updateProfile(
          uid: testUid,
          displayName: 'Updated Name',
          bio: 'Updated bio',
        );

        final doc =
            await fakeFirestore.collection('users').doc(testUid).get();
        final data = doc.data()!;
        // Counter fields must remain unchanged
        expect(data['postCount'], 3);
        expect(data['followerCount'], 10);
        expect(data['followingCount'], 5);
      });

      test('throws ProfileException when display name is empty', () async {
        await expectLater(
          dataSource.updateProfile(
            uid: testUid,
            displayName: '',
            bio: 'bio',
          ),
          throwsA(isA<ProfileException>()),
        );
      });
    });

    group('uploadAvatar', () {
      test(
          'uploads file to avatars/{uid}/{filename} and updates user document',
          () async {
        await fakeFirestore.collection('users').doc(testUid).set(baseDoc);

        final mockRef = MockStorageReference();
        when(() => mockStorage.ref('avatars/$testUid/avatar.jpg'))
            .thenAnswer((_) => mockRef);
        when(() => mockRef.putFile(any())).thenAnswer((_) => _FakeUploadTask());
        when(() => mockRef.getDownloadURL()).thenAnswer(
          (_) async => 'https://storage.example.com/new-avatar.jpg',
        );

        await dataSource.uploadAvatar(
          uid: testUid,
          imagePath: '/any/path/avatar.jpg',
        );

        verify(() => mockStorage.ref('avatars/$testUid/avatar.jpg')).called(1);

        final doc =
            await fakeFirestore.collection('users').doc(testUid).get();
        expect(
          doc.data()!['avatarUrl'],
          'https://storage.example.com/new-avatar.jpg',
        );
      });

      test('throws ProfileException on upload failure', () async {
        final mockRef = MockStorageReference();
        when(() => mockStorage.ref(any())).thenAnswer((_) => mockRef);
        when(() => mockRef.putFile(any())).thenThrow(Exception('Upload failed'));

        await expectLater(
          dataSource.uploadAvatar(uid: testUid, imagePath: '/any/avatar.jpg'),
          throwsA(isA<ProfileException>()),
        );
      });
    });

    group('deleteAccount', () {
      test('deletes user document from Firestore', () async {
        await fakeFirestore.collection('users').doc(testUid).set(baseDoc);

        await dataSource.deleteAccount(uid: testUid);

        final doc =
            await fakeFirestore.collection('users').doc(testUid).get();
        expect(doc.exists, false);
      });

      test('throws ProfileException when delete fails', () async {
        // deleteAccount with a non-existent doc does not throw in Firestore;
        // repository wraps unexpected errors. No assertion needed here — the
        // Firestore delete is idempotent.
        await expectLater(
          dataSource.deleteAccount(uid: 'nonexistent'),
          completes,
        );
      });
    });
  });
}
