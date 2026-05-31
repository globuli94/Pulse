import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/home/presentation/screens/shell_screen.dart';
import 'package:pulse/features/notifications/presentation/bloc/unread_notifications_count_cubit.dart';
import 'package:pulse/features/home/presentation/bloc/shell_tab_cubit.dart';

class MockUnreadNotificationsCountCubit extends Mock
    implements UnreadNotificationsCountCubit {}

class MockShellTabCubit extends Mock implements ShellTabCubit {}

void main() {
  group('NotificationBellButton', () {
    late MockUnreadNotificationsCountCubit mockUnreadNotificationsCountCubit;
    late MockShellTabCubit mockShellTabCubit;

    setUp(() {
      mockUnreadNotificationsCountCubit =
          MockUnreadNotificationsCountCubit();
      mockShellTabCubit = MockShellTabCubit();

      // Default mock setup
      when(() => mockShellTabCubit.state).thenReturn(0);
      when(() => mockShellTabCubit.stream)
          .thenAnswer((_) => Stream.value(0));
    });

    testWidgets(
        'renders Stack with clipBehavior: Clip.none when unreadCount > 0',
        (tester) async {
      when(() => mockUnreadNotificationsCountCubit.state).thenReturn(5);
      when(() => mockUnreadNotificationsCountCubit.stream)
          .thenAnswer((_) => Stream.value(5));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<UnreadNotificationsCountCubit>.value(
                value: mockUnreadNotificationsCountCubit,
              ),
              BlocProvider<ShellTabCubit>.value(
                value: mockShellTabCubit,
              ),
            ],
            child: const ShellScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify that a Stack with clipBehavior: Clip.none exists in the widget tree
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Stack &&
              widget.clipBehavior == Clip.none,
        ),
        findsWidgets,
        reason: 'Expected Stack with clipBehavior: Clip.none when unreadCount > 0',
      );
    });

    testWidgets(
        'renders no Stack with clipBehavior: Clip.none when unreadCount is 0',
        (tester) async {
      when(() => mockUnreadNotificationsCountCubit.state).thenReturn(0);
      when(() => mockUnreadNotificationsCountCubit.stream)
          .thenAnswer((_) => Stream.value(0));

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<UnreadNotificationsCountCubit>.value(
                value: mockUnreadNotificationsCountCubit,
              ),
              BlocProvider<ShellTabCubit>.value(
                value: mockShellTabCubit,
              ),
            ],
            child: const ShellScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify that no Stack with clipBehavior: Clip.none exists
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Stack &&
              widget.clipBehavior == Clip.none,
        ),
        findsNothing,
        reason: 'Expected no Stack with clipBehavior: Clip.none when unreadCount is 0',
      );
    });

    testWidgets('updates widget tree when unreadCount changes from 0 to > 0',
        (tester) async {
      final streamController = StreamController<int>.broadcast();

      when(() => mockUnreadNotificationsCountCubit.state).thenReturn(0);
      when(() => mockUnreadNotificationsCountCubit.stream)
          .thenAnswer((_) => streamController.stream);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<UnreadNotificationsCountCubit>.value(
                value: mockUnreadNotificationsCountCubit,
              ),
              BlocProvider<ShellTabCubit>.value(
                value: mockShellTabCubit,
              ),
            ],
            child: const ShellScreen(),
          ),
        ),
      );

      await tester.pump();

      // Initially, no Stack with clipBehavior: Clip.none
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Stack &&
              widget.clipBehavior == Clip.none,
        ),
        findsNothing,
      );

      // Emit unreadCount > 0
      streamController.add(3);
      await tester.pump();

      // Now, Stack with clipBehavior: Clip.none should be present
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Stack &&
              widget.clipBehavior == Clip.none,
        ),
        findsWidgets,
      );

      await streamController.close();
    });
  });
}
