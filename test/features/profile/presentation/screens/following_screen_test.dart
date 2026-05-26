// test/features/profile/presentation/screens/following_screen_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/follows/domain/repositories/follows_repository.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/following_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/following_screen.dart';
import 'package:pulse/features/profile/presentation/widgets/follow_user_tile.dart';

class MockFollowingBloc extends MockBloc<FollowingEvent, FollowingState>
    implements FollowingBloc {}

class MockFollowsRepository extends Mock implements FollowsRepository {}

Widget _buildSubject(FollowingBloc bloc) {
  return MaterialApp(
    home: BlocProvider<FollowingBloc>.value(
      value: bloc,
      child: const FollowingScreen(viewedUid: 'test-uid'),
    ),
  );
}

void main() {
  late MockFollowingBloc mockFollowingBloc;

  final testFollowing = UserProfile(
    uid: 'following-1',
    displayName: 'Following One',
    bio: '',
    avatarUrl: null,
    postCount: 0,
  );

  setUp(() {
    mockFollowingBloc = MockFollowingBloc();
  });

  tearDown(() {
    mockFollowingBloc.close();
  });

  group('FollowingScreen', () {
    testWidgets('shows CircularProgressIndicator while loading',
        (WidgetTester tester) async {
      when(() => mockFollowingBloc.state).thenReturn(const FollowingLoading());
      whenListen(
        mockFollowingBloc,
        Stream.value(const FollowingLoading()),
        initialState: const FollowingLoading(),
      );

      await tester.pumpWidget(_buildSubject(mockFollowingBloc));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows FollowUserTile list when FollowingLoaded',
        (WidgetTester tester) async {
      final state = FollowingLoaded(following: [testFollowing]);
      when(() => mockFollowingBloc.state).thenReturn(state);
      whenListen(
        mockFollowingBloc,
        Stream.value(state),
        initialState: state,
      );

      await tester.pumpWidget(_buildSubject(mockFollowingBloc));
      await tester.pump();

      expect(find.byType(FollowUserTile), findsOneWidget);
      expect(find.text('Following One'), findsOneWidget);
    });

    testWidgets('shows empty message when FollowingLoaded with empty list',
        (WidgetTester tester) async {
      const state = FollowingLoaded(following: []);
      when(() => mockFollowingBloc.state).thenReturn(state);
      whenListen(
        mockFollowingBloc,
        Stream.value(state),
        initialState: state,
      );

      await tester.pumpWidget(_buildSubject(mockFollowingBloc));
      await tester.pump();

      expect(find.text('Not following anyone yet.'), findsOneWidget);
    });

    testWidgets('shows error message when FollowingError',
        (WidgetTester tester) async {
      const state = FollowingError(message: 'Failed to load following');
      when(() => mockFollowingBloc.state).thenReturn(state);
      whenListen(
        mockFollowingBloc,
        Stream.value(state),
        initialState: state,
      );

      await tester.pumpWidget(_buildSubject(mockFollowingBloc));
      await tester.pump();

      expect(find.text('Failed to load following'), findsOneWidget);
    });

    testWidgets('shows Following in AppBar title', (WidgetTester tester) async {
      when(() => mockFollowingBloc.state).thenReturn(const FollowingInitial());
      whenListen(
        mockFollowingBloc,
        Stream.value(const FollowingInitial()),
        initialState: const FollowingInitial(),
      );

      await tester.pumpWidget(_buildSubject(mockFollowingBloc));
      await tester.pump();

      expect(find.text('Following'), findsOneWidget);
    });
  });
}
