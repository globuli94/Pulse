// test/screenshots/comments_screenshots_test.dart
//
// Golden screenshot tests for the Comments on Posts feature.
// Run with: flutter test --update-goldens test/screenshots/comments_screenshots_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/auth/domain/entities/app_user.dart';
import 'package:pulse/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse/features/comments/domain/entities/comment.dart';
import 'package:pulse/features/comments/domain/repositories/comments_repository.dart';
import 'package:pulse/features/comments/presentation/bloc/comments_bloc.dart';
import 'package:pulse/features/comments/presentation/screens/comments_screen.dart';
import 'package:pulse/features/posts/domain/entities/post.dart';
import 'package:pulse/features/posts/domain/repositories/posts_repository.dart';
import 'package:pulse/features/posts/presentation/bloc/posts_feed_bloc.dart';
import 'package:pulse/features/posts/presentation/widgets/post_card.dart';
import 'package:pulse/features/profile/domain/repositories/profile_repository.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockAuthBloc extends Mock implements AuthBloc {}

class MockPostsRepository extends Mock implements PostsRepository {}

class MockPostsFeedBloc extends Mock implements PostsFeedBloc {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockCommentsRepository extends Mock implements CommentsRepository {}

// Pre-seeded CommentsBloc mock — avoids pumpAndSettle hangs from emit.forEach
class MockCommentsBloc extends MockBloc<CommentsEvent, CommentsState>
    implements CommentsBloc {}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

final _tUser = AppUser(
  uid: 'viewer-uid',
  email: 'viewer@example.com',
  displayName: 'Viewer User',
);

final _tPost = Post(
  id: 'post-123',
  userId: 'author-uid',
  text: 'Just visited the new coffee shop downtown ☕ — highly recommend!',
  createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
  imageUrl: null,
  likeCount: 12,
);

final _tComments = [
  Comment(
    id: 'c1',
    postId: 'post-123',
    authorId: 'user-a',
    text: 'That place is amazing! The cold brew is top notch.',
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
  Comment(
    id: 'c2',
    postId: 'post-123',
    authorId: 'user-b',
    text: 'Agreed, went last week. The pastries are great too 🥐',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  Comment(
    id: 'c3',
    postId: 'post-123',
    authorId: 'viewer-uid',
    text: 'Definitely adding it to my weekend list!',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Phone-sized surface for screenshots.
const _phoneSize = Size(390, 844);

Future<void> _setPhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_phoneSize);
  addTearDown(() async => tester.binding.setSurfaceSize(null));
}

/// Author display names keyed by uid.
const _authorNames = {
  'author-uid': 'Alex Rivera',
  'user-a': 'Jordan Kim',
  'user-b': 'Sam Patel',
  'viewer-uid': 'Viewer User',
};

void main() {
  late MockAuthBloc authBloc;
  late MockPostsRepository postsRepository;
  late MockPostsFeedBloc postsFeedBloc;
  late MockProfileRepository profileRepository;
  late MockCommentsRepository commentsRepository;

  setUp(() {
    authBloc = MockAuthBloc();
    postsRepository = MockPostsRepository();
    postsFeedBloc = MockPostsFeedBloc();
    profileRepository = MockProfileRepository();
    commentsRepository = MockCommentsRepository();

    when(() => authBloc.state).thenReturn(Authenticated(_tUser));
    when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => postsFeedBloc.state)
        .thenReturn(const PostsFeedLoaded(posts: []));
    when(() => postsFeedBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => postsRepository.watchIsLiked(
          postId: any(named: 'postId'),
          userId: any(named: 'userId'),
        )).thenAnswer((_) => Stream.value(false));
    when(() => postsRepository.watchLikeCount(any()))
        .thenAnswer((_) => Stream.value(12));

    when(() => profileRepository.watchUserDisplayInfo(any())).thenAnswer(
      (inv) {
        final uid = inv.positionalArguments.first as String;
        return Stream.value((
          displayName: _authorNames[uid] ?? 'Unknown User',
          avatarUrl: null,
        ));
      },
    );

    when(() => commentsRepository.watchCommentCount(any()))
        .thenAnswer((_) => Stream.value(3));
  });

  // -------------------------------------------------------------------------
  // Screenshot 1: Feed card with comment count button
  // -------------------------------------------------------------------------
  testWidgets('screenshot — feed card with comment count button',
      (WidgetTester tester) async {
    await _setPhoneSize(tester);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<PostsRepository>.value(value: postsRepository),
          RepositoryProvider<ProfileRepository>.value(
              value: profileRepository),
          RepositoryProvider<CommentsRepository>.value(
              value: commentsRepository),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<PostsFeedBloc>.value(value: postsFeedBloc),
            ],
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F5F5),
              body: SafeArea(child: PostCard(post: _tPost)),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../screenshots/comments/01_feed_card_with_comment_count.png',
      ),
    );
  });

  // -------------------------------------------------------------------------
  // Screenshot 2: Comments list (pre-seeded loaded state)
  // -------------------------------------------------------------------------
  testWidgets('screenshot — comments screen with loaded comments list',
      (WidgetTester tester) async {
    await _setPhoneSize(tester);

    // Pre-seed the bloc with CommentsLoaded so no async subscription is needed
    final commentsBloc = MockCommentsBloc();
    when(() => commentsBloc.state)
        .thenReturn(CommentsLoaded(comments: _tComments));
    whenListen(
      commentsBloc,
      Stream.value(CommentsLoaded(comments: _tComments)),
      initialState: CommentsLoaded(comments: _tComments),
    );

    await tester.pumpWidget(
      RepositoryProvider<ProfileRepository>.value(
        value: profileRepository,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BlocProvider<CommentsBloc>.value(
            value: commentsBloc,
            child: CommentsScreen(
              postId: 'post-123',
              currentUserId: _tUser.uid,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/comments/02_comments_list.png'),
    );
  });

  // -------------------------------------------------------------------------
  // Screenshot 3: Comment input UI (empty state, input focused)
  // -------------------------------------------------------------------------
  testWidgets('screenshot — comments screen comment input UI',
      (WidgetTester tester) async {
    await _setPhoneSize(tester);

    final commentsBloc = MockCommentsBloc();
    when(() => commentsBloc.state)
        .thenReturn(CommentsLoaded(comments: _tComments));
    whenListen(
      commentsBloc,
      Stream.value(CommentsLoaded(comments: _tComments)),
      initialState: CommentsLoaded(comments: _tComments),
    );

    await tester.pumpWidget(
      RepositoryProvider<ProfileRepository>.value(
        value: profileRepository,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: BlocProvider<CommentsBloc>.value(
            value: commentsBloc,
            child: CommentsScreen(
              postId: 'post-123',
              currentUserId: _tUser.uid,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap the text field to focus it — shows the input row clearly
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../screenshots/comments/03_comment_input_ui.png',
      ),
    );
  });
}
