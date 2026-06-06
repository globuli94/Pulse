import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/comments/domain/entities/comment.dart';
import 'package:pulse/features/comments/domain/repositories/comments_repository.dart';
import 'package:pulse/features/comments/presentation/bloc/comments_bloc.dart';

class MockCommentsRepository extends Mock implements CommentsRepository {}

void main() {
  group('CommentsBloc', () {
    late MockCommentsRepository mockCommentsRepository;

    final tComment1 = Comment(
      id: 'c1',
      postId: 'p1',
      authorId: 'u1',
      text: 'Hello',
      createdAt: DateTime(2024, 1, 1),
    );

    final tComment2 = Comment(
      id: 'c2',
      postId: 'p1',
      authorId: 'u2',
      text: 'World',
      createdAt: DateTime(2024, 1, 2),
    );

    setUp(() {
      mockCommentsRepository = MockCommentsRepository();
      when(() => mockCommentsRepository.watchComments(postId: any(named: 'postId')))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockCommentsRepository.addComment(
            postId: any(named: 'postId'),
            authorId: any(named: 'authorId'),
            text: any(named: 'text'),
          )).thenAnswer((_) => Future.value());
    });

    group('CommentsSubscriptionRequested', () {
      blocTest<CommentsBloc, CommentsState>(
        'TC-1: emits [CommentsLoading, CommentsLoaded(comments: [])] when stream emits empty list',
        build: () {
          when(() => mockCommentsRepository.watchComments(postId: 'p1'))
              .thenAnswer((_) => Stream.value([]));
          return CommentsBloc(repository: mockCommentsRepository);
        },
        act: (bloc) => bloc.add(const CommentsSubscriptionRequested(postId: 'p1')),
        expect: () => [
          isA<CommentsLoading>(),
          isA<CommentsLoaded>().having((s) => s.comments, 'comments', isEmpty),
        ],
      );

      blocTest<CommentsBloc, CommentsState>(
        'TC-2: emits [CommentsLoading, CommentsLoaded(comments: [comment1, comment2])] when stream emits 2 comments in oldest-first order',
        build: () {
          when(() => mockCommentsRepository.watchComments(postId: 'p1'))
              .thenAnswer((_) => Stream.value([tComment1, tComment2]));
          return CommentsBloc(repository: mockCommentsRepository);
        },
        act: (bloc) => bloc.add(const CommentsSubscriptionRequested(postId: 'p1')),
        expect: () => [
          isA<CommentsLoading>(),
          isA<CommentsLoaded>()
              .having((s) => s.comments, 'comments', [tComment1, tComment2])
              .having((s) => s.comments.first.createdAt.isBefore(s.comments.last.createdAt),
                  'oldest first', true),
        ],
      );

      blocTest<CommentsBloc, CommentsState>(
        'TC-3: emits [CommentsLoading, CommentsError(...)] when stream errors',
        build: () {
          when(() => mockCommentsRepository.watchComments(postId: 'p1'))
              .thenAnswer((_) => Stream.error(Exception('Network error')));
          return CommentsBloc(repository: mockCommentsRepository);
        },
        act: (bloc) => bloc.add(const CommentsSubscriptionRequested(postId: 'p1')),
        expect: () => [
          isA<CommentsLoading>(),
          isA<CommentsError>()
              .having((s) => s.message, 'message', contains('Network error')),
        ],
      );
    });

    group('CommentAddRequested', () {
      blocTest<CommentsBloc, CommentsState>(
        'TC-4: calls addComment with correct arguments',
        build: () => CommentsBloc(repository: mockCommentsRepository),
        act: (bloc) => bloc.add(const CommentAddRequested(
          postId: 'p1',
          authorId: 'u1',
          text: 'Great post!',
        )),
        verify: (_) {
          verify(() => mockCommentsRepository.addComment(
            postId: 'p1',
            authorId: 'u1',
            text: 'Great post!',
          )).called(1);
        },
      );

      blocTest<CommentsBloc, CommentsState>(
        'TC-5: does NOT emit error state when addComment throws (errors are swallowed)',
        build: () {
          when(() => mockCommentsRepository.addComment(
            postId: 'p1',
            authorId: 'u1',
            text: 'Great post!',
          )).thenThrow(Exception('Firestore error'));
          return CommentsBloc(repository: mockCommentsRepository);
        },
        seed: () => CommentsLoaded(comments: [tComment1]),
        act: (bloc) => bloc.add(const CommentAddRequested(
          postId: 'p1',
          authorId: 'u1',
          text: 'Great post!',
        )),
        expect: () => [],
      );
    });
  });
}
