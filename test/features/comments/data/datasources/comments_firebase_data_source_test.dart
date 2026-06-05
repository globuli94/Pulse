import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/features/comments/data/datasources/comments_firebase_data_source.dart';

void main() {
  group('CommentsFirebaseDataSource', () {
    late FakeFirebaseFirestore fakeFirestore;
    late CommentsFirebaseDataSource dataSource;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = CommentsFirebaseDataSource(firestore: fakeFirestore);
    });

    group('watchComments', () {
      test('TC-1: emits empty list when no comments exist for postId', () async {
        final stream = dataSource.watchComments(postId: 'p1');
        final comments = await stream.first;

        expect(comments, isEmpty);
      });

      test('TC-2: emits comments for the correct postId in ascending createdAt order',
          () async {
        // Arrange: create comments (add in reverse order to test sorting)
        await fakeFirestore.collection('comments').doc('c2').set({
          'postId': 'p1',
          'authorId': 'u2',
          'text': 'Second comment',
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
        });

        await fakeFirestore.collection('comments').doc('c1').set({
          'postId': 'p1',
          'authorId': 'u1',
          'text': 'First comment',
          'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        });

        // Act
        final stream = dataSource.watchComments(postId: 'p1');
        final comments = await stream.first;

        // Assert
        expect(comments.length, 2);
        expect(comments[0]['id'], 'c1');
        expect(comments[0]['text'], 'First comment');
        expect(comments[1]['id'], 'c2');
        expect(comments[1]['text'], 'Second comment');
      });

      test('TC-3: does NOT include comments from a different postId', () async {
        // Arrange: create comments for different posts
        await fakeFirestore.collection('comments').doc('c1').set({
          'postId': 'p1',
          'authorId': 'u1',
          'text': 'Comment on post 1',
          'createdAt': Timestamp.now(),
        });

        await fakeFirestore.collection('comments').doc('c2').set({
          'postId': 'p2',
          'authorId': 'u1',
          'text': 'Comment on post 2',
          'createdAt': Timestamp.now(),
        });

        // Act
        final stream = dataSource.watchComments(postId: 'p1');
        final comments = await stream.first;

        // Assert
        expect(comments.length, 1);
        expect(comments[0]['postId'], 'p1');
      });
    });

    group('watchCommentCount', () {
      test('TC-4: emits 0 when no comments for postId', () async {
        final stream = dataSource.watchCommentCount('p1');
        final count = await stream.first;

        expect(count, 0);
      });

      test('TC-5: emits correct count after adding 2 comments', () async {
        // Arrange: add 2 comments
        await fakeFirestore.collection('comments').doc('c1').set({
          'postId': 'p1',
          'authorId': 'u1',
          'text': 'Comment 1',
          'createdAt': Timestamp.now(),
        });

        await fakeFirestore.collection('comments').doc('c2').set({
          'postId': 'p1',
          'authorId': 'u2',
          'text': 'Comment 2',
          'createdAt': Timestamp.now(),
        });

        // Act
        final stream = dataSource.watchCommentCount('p1');
        final count = await stream.first;

        // Assert
        expect(count, 2);
      });
    });

    group('addComment', () {
      test('TC-6: comment document written with correct fields', () async {
        // Arrange
        const postId = 'p1';
        const authorId = 'u1';
        const text = 'Test comment';

        // Act
        await dataSource.addComment(
          postId: postId,
          authorId: authorId,
          text: text,
        );

        // Assert: verify comment was written
        final snap = await fakeFirestore
            .collection('comments')
            .where('postId', isEqualTo: postId)
            .get();

        expect(snap.docs.length, 1);
        final comment = snap.docs.first.data();
        expect(comment['postId'], postId);
        expect(comment['authorId'], authorId);
        expect(comment['text'], text);
        expect(comment['createdAt'], isA<Timestamp>());
      });

      test('TC-7: notification written when authorId != postOwnerUid', () async {
        // Arrange: create a post owned by a different user
        const postId = 'p1';
        const postOwnerUid = 'owner1';
        const commenterUid = 'commenter1';
        const commenterName = 'Alice';

        await fakeFirestore.collection('posts').doc(postId).set({
          'userId': postOwnerUid,
        });

        await fakeFirestore.collection('users').doc(commenterUid).set({
          'displayName': commenterName,
        });

        // Act
        await dataSource.addComment(
          postId: postId,
          authorId: commenterUid,
          text: 'Great post!',
        );

        // Assert: verify notification was written
        final notifSnap =
            await fakeFirestore.collection('notifications').get();

        expect(notifSnap.docs.length, 1);
        final notification = notifSnap.docs.first.data();
        expect(notification['userId'], postOwnerUid);
        expect(notification['actorId'], commenterUid);
        expect(notification['actorDisplayName'], commenterName);
        expect(notification['postId'], postId);
      });

      test('TC-8: notification NOT written when authorId == postOwnerUid', () async {
        // Arrange: post owner comments on own post
        const postId = 'p1';
        const ownerUid = 'owner1';

        await fakeFirestore.collection('posts').doc(postId).set({
          'userId': ownerUid,
        });

        await fakeFirestore.collection('users').doc(ownerUid).set({
          'displayName': 'Post Owner',
        });

        // Act
        await dataSource.addComment(
          postId: postId,
          authorId: ownerUid,
          text: 'My own comment',
        );

        // Assert: no notification written
        final notifSnap =
            await fakeFirestore.collection('notifications').get();

        expect(notifSnap.docs.length, 0);
      });

      test('TC-9: notification type field is "comment"', () async {
        // Arrange
        const postId = 'p1';
        const postOwnerUid = 'owner1';
        const commenterUid = 'commenter1';

        await fakeFirestore.collection('posts').doc(postId).set({
          'userId': postOwnerUid,
        });

        await fakeFirestore.collection('users').doc(commenterUid).set({
          'displayName': 'Commenter',
        });

        // Act
        await dataSource.addComment(
          postId: postId,
          authorId: commenterUid,
          text: 'Nice!',
        );

        // Assert
        final notifSnap =
            await fakeFirestore.collection('notifications').get();

        final notification = notifSnap.docs.first.data();
        expect(notification['type'], 'comment');
      });

      test('TC-10: notification has correct userId, actorId, postId', () async {
        // Arrange
        const postId = 'p1';
        const postOwnerUid = 'owner123';
        const commenterUid = 'commenter456';

        await fakeFirestore.collection('posts').doc(postId).set({
          'userId': postOwnerUid,
        });

        await fakeFirestore.collection('users').doc(commenterUid).set({
          'displayName': 'Test User',
        });

        // Act
        await dataSource.addComment(
          postId: postId,
          authorId: commenterUid,
          text: 'Comment text',
        );

        // Assert
        final notifSnap =
            await fakeFirestore.collection('notifications').get();

        final notification = notifSnap.docs.first.data();
        expect(notification['userId'], postOwnerUid);
        expect(notification['actorId'], commenterUid);
        expect(notification['postId'], postId);
      });
    });
  });
}
