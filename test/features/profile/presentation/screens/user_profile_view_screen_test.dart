// Copyright 2024 Social Media Company. All rights reserved.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/chat/domain/entities/conversation.dart';
import 'package:pulse/features/chat/domain/entities/message.dart';
import 'package:pulse/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse/features/follows/presentation/bloc/follow_bloc.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_posts_bloc.dart';
import 'package:pulse/features/profile/presentation/bloc/user_profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/user_profile_view_screen.dart';

class MockUserProfileBloc extends MockBloc<UserProfileEvent, UserProfileState>
    implements UserProfileBloc {}

class MockFollowBloc extends MockBloc<FollowEvent, FollowState>
    implements FollowBloc {}

class MockProfilePostsBloc extends MockBloc<ProfilePostsEvent, ProfilePostsState>
    implements ProfilePostsBloc {}

class MockChatRepository extends Mock implements ChatRepository {
  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return const Stream.empty();
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return const Stream.empty();
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String otherUserId,
    required String text,
  }) async {}

  @override
  Future<String> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) async =>
      'conv1';

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {}
}

void main() {
  late MockUserProfileBloc mockUserProfileBloc;
  late MockFollowBloc mockFollowBloc;
  late MockProfilePostsBloc mockProfilePostsBloc;
  late MockChatRepository mockChatRepository;

  setUpAll(() {
    registerFallbackValue(const FollowStatusCheckRequested(
      followerId: 'fallback-follower',
      followeeId: 'fallback-followee',
    ));
  });

  setUp(() {
    mockUserProfileBloc = MockUserProfileBloc();
    mockFollowBloc = MockFollowBloc();
    mockProfilePostsBloc = MockProfilePostsBloc();
    mockChatRepository = MockChatRepository();
    // Ensure the mock blocs have proper initial states
    whenListen(
      mockUserProfileBloc,
      Stream.value(const UserProfileLoading()),
      initialState: const UserProfileLoading(),
    );
    whenListen(
      mockFollowBloc,
      Stream.value(const FollowInitial()),
      initialState: const FollowInitial(),
    );
    whenListen(
      mockProfilePostsBloc,
      Stream.value(const ProfilePostsInitial()),
      initialState: const ProfilePostsInitial(),
    );
  });

  Widget createWidgetUnderTest({
    required String viewedUid,
    required String currentUserId,
  }) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChatRepository>(create: (_) => mockChatRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UserProfileBloc>.value(value: mockUserProfileBloc),
          BlocProvider<FollowBloc>.value(value: mockFollowBloc),
          BlocProvider<ProfilePostsBloc>.value(value: mockProfilePostsBloc),
        ],
        child: MaterialApp(
          home: UserProfileViewScreen(
            viewedUid: viewedUid,
            currentUserId: currentUserId,
          ),
        ),
      ),
    );
  }

  group('UserProfileViewScreen', () {
    testWidgets('shows loading state with CircularProgressIndicator',
        (WidgetTester tester) async {
      when(() => mockUserProfileBloc.state)
          .thenReturn(const UserProfileLoading());
      when(() => mockFollowBloc.state).thenReturn(const FollowInitial());

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays user display name when loaded',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'John Doe',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.text('John Doe'), findsWidgets);
    });

    testWidgets(
        'displays followerCount and followingCount when loaded',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Jane Doe',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 42,
        followingCount: 7,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.textContaining('42'), findsWidgets);
      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets(
        'shows Follow button when viewing other user and not following',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User To Follow',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.widgetWithText(FilledButton, 'Follow'), findsWidgets);
    });

    testWidgets(
        'shows Unfollow button when viewing other user and already following',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Already Following',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 50,
        followingCount: 30,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: true));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.widgetWithText(OutlinedButton, 'Unfollow'), findsWidgets);
    });

    testWidgets('hides follow button on own profile',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'current-uid',
        displayName: 'My Profile',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 20,
        followingCount: 15,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'current-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.text('Follow'), findsNothing);
      expect(find.text('Unfollow'), findsNothing);
    });

    testWidgets('shows loading indicator when FollowBloc is loading',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state).thenReturn(const FollowLoading());

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows Retry button when FollowBloc fails',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowFailure(error: 'Network error'));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.widgetWithText(FilledButton, 'Retry'), findsWidgets);
    });

    testWidgets('dispatches FollowRequested when Follow button tapped',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'User To Follow',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Follow').first);
      await tester.pump();

      verify(() => mockFollowBloc.add(any(
          that: isA<FollowRequested>()
              .having((e) => e.followerId, 'followerId', 'current-uid')
              .having((e) => e.followeeId, 'followeeId', 'other-uid'))))
          .called(1);
    });

    testWidgets('dispatches UnfollowRequested when Unfollow button tapped',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Already Following',
        bio: 'Test bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 50,
        followingCount: 30,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: true));

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Unfollow').first);
      await tester.pump();

      verify(() => mockFollowBloc.add(any(
          that: isA<UnfollowRequested>()
              .having((e) => e.followerId, 'followerId', 'current-uid')
              .having((e) => e.followeeId, 'followeeId', 'other-uid'))))
          .called(1);
    });

    testWidgets('renders content inside CustomScrollView when loaded',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Scroll Test User',
        bio: 'Bio text',
        avatarUrl: null,
        postCount: 3,
        followerCount: 10,
        followingCount: 5,
      );

      when(() => mockUserProfileBloc.state)
          .thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state)
          .thenReturn(const FollowLoaded(isFollowing: false));
      when(() => mockProfilePostsBloc.state)
          .thenReturn(const ProfilePostsInitial());

      await tester.pumpWidget(
        createWidgetUnderTest(
          viewedUid: 'other-uid',
          currentUserId: 'current-uid',
        ),
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when ProfilePostsLoading',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Poster User',
        bio: '',
        avatarUrl: null,
        postCount: 0,
        followerCount: 0,
        followingCount: 0,
      );

      when(() => mockUserProfileBloc.state).thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state).thenReturn(const FollowLoaded(isFollowing: false));
      when(() => mockProfilePostsBloc.state).thenReturn(const ProfilePostsLoading());

      await tester.pumpWidget(
        createWidgetUnderTest(viewedUid: 'other-uid', currentUserId: 'current-uid'),
      );

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows "No posts yet." when ProfilePostsLoaded with empty list',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Empty Poster',
        bio: '',
        avatarUrl: null,
        postCount: 0,
        followerCount: 0,
        followingCount: 0,
      );

      when(() => mockUserProfileBloc.state).thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state).thenReturn(const FollowLoaded(isFollowing: false));
      when(() => mockProfilePostsBloc.state)
          .thenReturn(const ProfilePostsLoaded(posts: []));

      await tester.pumpWidget(
        createWidgetUnderTest(viewedUid: 'other-uid', currentUserId: 'current-uid'),
      );

      expect(find.text('No posts yet.'), findsOneWidget);
    });

    testWidgets('shows error message when ProfilePostsError',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'other-uid',
        displayName: 'Error User',
        bio: '',
        avatarUrl: null,
        postCount: 0,
        followerCount: 0,
        followingCount: 0,
      );

      when(() => mockUserProfileBloc.state).thenReturn(UserProfileLoaded(profile));
      when(() => mockFollowBloc.state).thenReturn(const FollowLoaded(isFollowing: false));
      when(() => mockProfilePostsBloc.state)
          .thenReturn(const ProfilePostsError(message: 'Failed to load posts'));

      await tester.pumpWidget(
        createWidgetUnderTest(viewedUid: 'other-uid', currentUserId: 'current-uid'),
      );

      expect(find.text('Failed to load posts'), findsOneWidget);
    });
  });
}
