import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/data/datasources/profile_firebase_data_source.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockUser extends Mock implements User {}
class MockReference extends Mock implements Reference {}

void main() {
  group('ProfileFirebaseDataSource', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseStorage mockFirebaseStorage;
    late ProfileFirebaseDataSource dataSource;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseStorage = MockFirebaseStorage();

      dataSource = ProfileFirebaseDataSource(
        firestore: fakeFirestore,
        storage: mockFirebaseStorage,
        firebaseAuth: mockFirebaseAuth,
      );
    });

    test(
      'updateProfile with displayName batch-updates posts for that user',
      () async {
        final uid = 'uid1';
        final oldDisplayName = 'Old Name';
        final newDisplayName = 'New Name';

        // Arrange: create a user document
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .set({
              'displayName': oldDisplayName,
              'email': 'test@example.com',
            });

        // Arrange: create a post document for this user
        await fakeFirestore
            .collection('posts')
            .doc('post1')
            .set({
              'userId': uid,
              'displayName': oldDisplayName,
              'text': 'Test post',
              'createdAt': Timestamp.now(),
            });

        // Act: update profile with new displayName
        await dataSource.updateProfile(
          uid: uid,
          displayName: newDisplayName,
        );

        // Assert: verify user document was updated
        final userDoc =
            await fakeFirestore.collection('users').doc(uid).get();
        expect(userDoc['displayName'], newDisplayName);

        // Assert: verify post document was batch-updated
        final postDoc =
            await fakeFirestore.collection('posts').doc('post1').get();
        expect(postDoc['displayName'], newDisplayName);
      },
    );

    test(
      'updateProfile with avatarUrl batch-updates posts for that user',
      () async {
        final uid = 'uid2';
        final displayName = 'User Name';
        final oldAvatarUrl = 'https://old.url/avatar.jpg';
        final newAvatarUrl = 'https://new.url/avatar.jpg';

        // Arrange: create a user document
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .set({
              'displayName': displayName,
              'avatarUrl': oldAvatarUrl,
              'email': 'test2@example.com',
            });

        // Arrange: create a post document for this user
        await fakeFirestore
            .collection('posts')
            .doc('post2')
            .set({
              'userId': uid,
              'displayName': displayName,
              'avatarUrl': oldAvatarUrl,
              'text': 'Another test post',
              'createdAt': Timestamp.now(),
            });

        // Act: update profile with new avatarUrl
        await dataSource.updateProfile(
          uid: uid,
          avatarUrl: newAvatarUrl,
        );

        // Assert: verify user document was updated
        final userDoc =
            await fakeFirestore.collection('users').doc(uid).get();
        expect(userDoc['avatarUrl'], newAvatarUrl);

        // Assert: verify post document was batch-updated
        final postDoc =
            await fakeFirestore.collection('posts').doc('post2').get();
        expect(postDoc['avatarUrl'], newAvatarUrl);
      },
    );

    test(
      'updateProfile with displayName and avatarUrl batch-updates posts',
      () async {
        final uid = 'uid3';
        final newDisplayName = 'Updated Name';
        final newAvatarUrl = 'https://updated.url/avatar.jpg';

        // Arrange: create a user document
        await fakeFirestore
            .collection('users')
            .doc(uid)
            .set({
              'displayName': 'Old Name',
              'avatarUrl': 'https://old.url/avatar.jpg',
              'email': 'test3@example.com',
            });

        // Arrange: create multiple post documents for this user
        await fakeFirestore
            .collection('posts')
            .doc('post3a')
            .set({
              'userId': uid,
              'displayName': 'Old Name',
              'avatarUrl': 'https://old.url/avatar.jpg',
              'text': 'Post 1',
              'createdAt': Timestamp.now(),
            });

        await fakeFirestore
            .collection('posts')
            .doc('post3b')
            .set({
              'userId': uid,
              'displayName': 'Old Name',
              'avatarUrl': 'https://old.url/avatar.jpg',
              'text': 'Post 2',
              'createdAt': Timestamp.now(),
            });

        // Act: update profile with new displayName and avatarUrl
        await dataSource.updateProfile(
          uid: uid,
          displayName: newDisplayName,
          avatarUrl: newAvatarUrl,
        );

        // Assert: verify both posts were updated
        final post3a =
            await fakeFirestore.collection('posts').doc('post3a').get();
        expect(post3a['displayName'], newDisplayName);
        expect(post3a['avatarUrl'], newAvatarUrl);

        final post3b =
            await fakeFirestore.collection('posts').doc('post3b').get();
        expect(post3b['displayName'], newDisplayName);
        expect(post3b['avatarUrl'], newAvatarUrl);
      },
    );

    test(
      'updateProfile does not update posts of other users',
      () async {
        final uid1 = 'uid1';
        final uid2 = 'uid2';
        final oldName = 'Old Name';
        final newName = 'New Name';

        // Arrange: create posts for different users
        await fakeFirestore.collection('users').doc(uid1).set({
          'displayName': oldName,
          'email': 'user1@example.com',
        });

        await fakeFirestore.collection('users').doc(uid2).set({
          'displayName': oldName,
          'email': 'user2@example.com',
        });

        await fakeFirestore.collection('posts').doc('post1').set({
          'userId': uid1,
          'displayName': oldName,
          'text': 'Post by user 1',
          'createdAt': Timestamp.now(),
        });

        await fakeFirestore.collection('posts').doc('post2').set({
          'userId': uid2,
          'displayName': oldName,
          'text': 'Post by user 2',
          'createdAt': Timestamp.now(),
        });

        // Act: update profile for uid1
        await dataSource.updateProfile(
          uid: uid1,
          displayName: newName,
        );

        // Assert: only uid1's post should be updated
        final post1 =
            await fakeFirestore.collection('posts').doc('post1').get();
        expect(post1['displayName'], newName);

        final post2 =
            await fakeFirestore.collection('posts').doc('post2').get();
        expect(post2['displayName'], oldName); // Should remain unchanged
      },
    );

    test(
      'deleteAccount() removes all owned content',
      () async {
        final uid = 'uid-test';
        final mockUser = MockUser();
        final mockRef = MockReference();

        // Arrange: set up auth to return a user with the test uid
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(uid);
        when(() => mockUser.delete()).thenAnswer((_) async {});

        // Arrange: set up storage mock
        when(() => mockFirebaseStorage.ref()).thenReturn(mockRef);
        when(() => mockRef.child(any())).thenReturn(mockRef);
        when(() => mockRef.delete()).thenAnswer((_) async {});

        // Arrange: seed firestore with data owned by uid-test
        await fakeFirestore
            .collection('posts')
            .doc('post1')
            .set({'userId': uid});

        await fakeFirestore
            .collection('likes')
            .doc('like1')
            .set({'userId': uid});

        await fakeFirestore
            .collection('follows')
            .doc('f1')
            .set({'followerId': uid, 'followeeId': 'other'});

        await fakeFirestore
            .collection('follows')
            .doc('f2')
            .set({'followerId': 'other', 'followeeId': uid});

        await fakeFirestore
            .collection('notifications')
            .doc('n1')
            .set({'userId': uid, 'actorId': 'other'});

        await fakeFirestore
            .collection('notifications')
            .doc('n2')
            .set({'userId': 'other', 'actorId': uid});

        await fakeFirestore
            .collection('conversations')
            .doc('c1')
            .set({'participantIds': [uid, 'other']});

        await fakeFirestore
            .collection('conversations')
            .doc('c1')
            .collection('messages')
            .doc('m1')
            .set({'text': 'hi'});

        await fakeFirestore.collection('users').doc(uid).set({
          'displayName': 'Test',
        });

        // Act
        await dataSource.deleteAccount();

        // Assert: verify all data owned by uid is deleted
        expect(
          (await fakeFirestore
                  .collection('posts')
                  .doc('post1')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore
                  .collection('likes')
                  .doc('like1')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore
                  .collection('follows')
                  .doc('f1')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore
                  .collection('follows')
                  .doc('f2')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore
                  .collection('notifications')
                  .doc('n1')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore
                  .collection('notifications')
                  .doc('n2')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore
                  .collection('conversations')
                  .doc('c1')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore
                  .collection('conversations')
                  .doc('c1')
                  .collection('messages')
                  .doc('m1')
                  .get())
              .exists,
          false,
        );

        expect(
          (await fakeFirestore.collection('users').doc(uid).get()).exists,
          false,
        );

        verify(() => mockUser.delete()).called(1);
      },
    );

    test(
      'deleteAccount() leaves other users\' content untouched',
      () async {
        final uid = 'uid-test';
        final otherUid = 'other-uid';
        final mockUser = MockUser();
        final mockRef = MockReference();

        // Arrange: set up auth to return a user with the test uid
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(uid);
        when(() => mockUser.delete()).thenAnswer((_) async {});

        // Arrange: set up storage mock
        when(() => mockFirebaseStorage.ref()).thenReturn(mockRef);
        when(() => mockRef.child(any())).thenReturn(mockRef);
        when(() => mockRef.delete()).thenAnswer((_) async {});

        // Arrange: seed firestore with data owned by uid-test and other-uid
        await fakeFirestore
            .collection('posts')
            .doc('post1')
            .set({'userId': uid});

        await fakeFirestore
            .collection('posts')
            .doc('other-post')
            .set({'userId': otherUid});

        await fakeFirestore
            .collection('users')
            .doc(uid)
            .set({'displayName': 'Test'});

        await fakeFirestore
            .collection('users')
            .doc(otherUid)
            .set({'displayName': 'Other'});

        // Act
        await dataSource.deleteAccount();

        // Assert: uid's content should be deleted
        expect(
          (await fakeFirestore
                  .collection('posts')
                  .doc('post1')
                  .get())
              .exists,
          false,
        );

        // Assert: other user's content should remain
        expect(
          (await fakeFirestore
                  .collection('posts')
                  .doc('other-post')
                  .get())
              .exists,
          true,
        );

        expect(
          (await fakeFirestore.collection('users').doc(otherUid).get()).exists,
          true,
        );
      },
    );

    test(
      'deleteAccount() throws when no user is signed in',
      () async {
        // Arrange: no user signed in
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => dataSource.deleteAccount(),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'deleteAccount() succeeds even if storage avatar is missing',
      () async {
        final uid = 'uid-test';
        final mockUser = MockUser();
        final mockRef = MockReference();

        // Arrange: set up auth to return a user with the test uid
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.uid).thenReturn(uid);
        when(() => mockUser.delete()).thenAnswer((_) async {});

        // Arrange: set up storage mock to throw object-not-found
        when(() => mockFirebaseStorage.ref()).thenReturn(mockRef);
        when(() => mockRef.child(any())).thenReturn(mockRef);
        when(() => mockRef.delete()).thenThrow(
          FirebaseException(plugin: 'storage', code: 'object-not-found'),
        );

        // Arrange: seed minimal firestore data
        await fakeFirestore.collection('users').doc(uid).set({
          'displayName': 'Test',
        });

        // Act & Assert: should complete without throwing
        await dataSource.deleteAccount();
        // If we reach here without exception, test passes
        expect(true, true);
      },
    );
  });
}
