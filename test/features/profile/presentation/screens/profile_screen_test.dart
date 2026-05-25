// Copyright 2024 Social Media Company. All rights reserved.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:pulse/features/profile/presentation/screens/profile_screen.dart';

class MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

void main() {
  late MockProfileBloc mockProfileBloc;

  setUp(() {
    mockProfileBloc = MockProfileBloc();
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

      when(() => mockProfileBloc.state)
          .thenReturn(ProfileLoaded(profile: profile));

      await tester.pumpWidget(
        BlocProvider<ProfileBloc>.value(
          value: mockProfileBloc,
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      expect(find.textContaining('10'), findsWidgets);
      expect(find.textContaining('5'), findsWidgets);
    });
  });
}
