import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/data/datasources/profile_firebase_data_source.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseStorage extends Mock implements FirebaseStorage {}

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
  });
}
