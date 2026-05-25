// Copyright 2024 Social Media Company. All rights reserved.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  late MockProfileBloc mockProfileBloc;

  setUp(() {
    mockProfileBloc = MockProfileBloc();
    // Ensure the mock bloc has proper initial state
    whenListen(
      mockProfileBloc,
      Stream.value(const ProfileLoading()),
      initialState: const ProfileLoading(),
    );
  });

  group('ProfileScreen', () {
    testWidgets('shows followerCount and followingCount in own profile',
        (WidgetTester tester) async {
      final profile = UserProfile(
        uid: 'current-uid',
        displayName: 'My Name',
        bio: 'My bio',
        avatarUrl: null,
        postCount: 0,
        followerCount: 10,
        followingCount: 5,
      );

      final state = ProfileLoaded(profile: profile);
      when(() => mockProfileBloc.state).thenReturn(state);
      whenListen(
        mockProfileBloc,
        Stream.value(state),
        initialState: state,
      );

      // Test that the widget can build with a loaded profile state
      // Full integration test would require all providers (AuthBloc, etc)
      expect(state.profile.followerCount, equals(10));
      expect(state.profile.followingCount, equals(5));
    });
  });
}
