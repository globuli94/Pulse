// test/features/profile/presentation/screens/followers_screen_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/followers_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/followers_screen.dart';
import 'package:pulse/features/profile/presentation/widgets/follow_user_tile.dart';

class MockFollowersBloc extends MockBloc<FollowersEvent, FollowersState>
    implements FollowersBloc {}

class MockFollowsRepository extends Mock implements FollowsRepository {}

Widget _buildSubject(FollowersBloc bloc) {
  return MaterialApp(
    home: BlocProvider<FollowersBloc>.value(
      value: bloc,
      child: const FollowersScreen(viewedUid: 'test-uid'),
    ),
  );
}

void main() {
  late MockFollowersBloc mockFollowersBloc;

  final testFollower = UserProfile(
    uid: 'follower-1',
    displayName: 'Follower One',
    bio: '',
    avatarUrl: null,
    postCount: 0,
  );

  setUp(() {
    mockFollowersBloc = MockFollowersBloc();
  });

  tearDown(() {
    mockFollowersBloc.close();
  });

  group('FollowersScreen', () {
    testWidgets('shows CircularProgressIndicator while loading',
        (WidgetTester tester) async {
      when(() => mockFollowersBloc.state).thenReturn(const FollowersLoading());
      whenListen(
        mockFollowersBloc,
        Stream.value(const FollowersLoading()),
        initialState: const FollowersLoading(),
      );

      await tester.pumpWidget(_buildSubject(mockFollowersBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows FollowUserTile list when FollowersLoaded',
        (WidgetTester tester) async {
      final state = FollowersLoaded(followers: [testFollower]);
      when(() => mockFollowersBloc.state).thenReturn(state);
      whenListen(
        mockFollowersBloc,
        Stream.value(state),
        initialState: state,
      );

      await tester.pumpWidget(_buildSubject(mockFollowersBloc));
      await tester.pump();

      expect(find.byType(FollowUserTile), findsOneWidget);
      expect(find.text('Follower One'), findsOneWidget);
    });

    testWidgets('shows empty message when FollowersLoaded with empty list',
        (WidgetTester tester) async {
      const state = FollowersLoaded(followers: []);
      when(() => mockFollowersBloc.state).thenReturn(state);
      whenListen(
        mockFollowersBloc,
        Stream.value(state),
        initialState: state,
      );

      await tester.pumpWidget(_buildSubject(mockFollowersBloc));
      await tester.pump();

      expect(find.text('No followers yet.'), findsOneWidget);
    });

    testWidgets('shows error message when FollowersError',
        (WidgetTester tester) async {
      const state = FollowersError(message: 'Failed to load followers');
      when(() => mockFollowersBloc.state).thenReturn(state);
      whenListen(
        mockFollowersBloc,
        Stream.value(state),
        initialState: state,
      );

      await tester.pumpWidget(_buildSubject(mockFollowersBloc));
      await tester.pump();

      expect(find.text('Failed to load followers'), findsOneWidget);
    });

    testWidgets('shows Followers in AppBar title', (WidgetTester tester) async {
      when(() => mockFollowersBloc.state).thenReturn(const FollowersInitial());
      whenListen(
        mockFollowersBloc,
        Stream.value(const FollowersInitial()),
        initialState: const FollowersInitial(),
      );

      await tester.pumpWidget(_buildSubject(mockFollowersBloc));
      await tester.pump();

      expect(find.text('Followers'), findsOneWidget);
    });
  });
}
