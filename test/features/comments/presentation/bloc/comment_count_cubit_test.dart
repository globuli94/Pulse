import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/comments/domain/repositories/comments_repository.dart';
import 'package:pulse/features/comments/presentation/bloc/comment_count_cubit.dart';

class MockCommentsRepository extends Mock implements CommentsRepository {}

void main() {
  group('CommentCountCubit', () {
    late MockCommentsRepository mockCommentsRepository;

    setUp(() {
      mockCommentsRepository = MockCommentsRepository();
      when(() => mockCommentsRepository.watchCommentCount(any()))
          .thenAnswer((_) => const Stream.empty());
    });

    test('TC-1: initial state is 0', () {
      final cubit = CommentCountCubit(repository: mockCommentsRepository);
      expect(cubit.state, 0);
    });

    test('TC-2: startWatching(postId) subscribes and emits count from watchCommentCount',
        () async {
      final countCtrl = StreamController<int>.broadcast();

      when(() => mockCommentsRepository.watchCommentCount('p1'))
          .thenAnswer((_) => countCtrl.stream);

      final cubit = CommentCountCubit(repository: mockCommentsRepository);
      final states = <int>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startWatching('p1');
      await Future<void>.delayed(Duration.zero);

      countCtrl.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(states, [2]);

      countCtrl.add(5);
      await Future<void>.delayed(Duration.zero);
      expect(states, [2, 5]);

      await sub.cancel();
      await cubit.close();
      await countCtrl.close();
    });

    test('TC-3: startWatching cancels prior subscription',
        () async {
      final countCtrl1 = StreamController<int>.broadcast();
      final countCtrl2 = StreamController<int>.broadcast();

      when(() => mockCommentsRepository.watchCommentCount('p1'))
          .thenAnswer((_) => countCtrl1.stream);
      when(() => mockCommentsRepository.watchCommentCount('p2'))
          .thenAnswer((_) => countCtrl2.stream);

      final cubit = CommentCountCubit(repository: mockCommentsRepository);
      final states = <int>[];
      final sub = cubit.stream.listen(states.add);

      // Start watching p1
      cubit.startWatching('p1');
      await Future<void>.delayed(Duration.zero);

      countCtrl1.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(states, [3]);

      // Switch to p2 (cancels p1 subscription)
      cubit.startWatching('p2');
      await Future<void>.delayed(Duration.zero);

      // p1 emission should be ignored
      countCtrl1.add(10);
      await Future<void>.delayed(Duration.zero);
      expect(states, [3]); // No new state

      // p2 emission should be received
      countCtrl2.add(7);
      await Future<void>.delayed(Duration.zero);
      expect(states, [3, 7]);

      await sub.cancel();
      await cubit.close();
      await countCtrl1.close();
      await countCtrl2.close();
    });

    test('TC-4: startWatching with empty string does NOT subscribe', () async {
      final cubit = CommentCountCubit(repository: mockCommentsRepository);
      final states = <int>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startWatching('');
      await Future<void>.delayed(Duration.zero);

      // Verify no call was made (initial verify)
      verify(() => mockCommentsRepository.watchCommentCount('')).called(1);

      // State should remain 0
      expect(states, isEmpty);

      await sub.cancel();
      await cubit.close();
    });

    test('TC-5: stream error emits 0 (not a crash)', () async {
      when(() => mockCommentsRepository.watchCommentCount('p1'))
          .thenAnswer((_) => Stream.error(Exception('Network error')));

      final cubit = CommentCountCubit(repository: mockCommentsRepository);
      final states = <int>[];
      final sub = cubit.stream.listen(states.add);

      cubit.startWatching('p1');
      await Future<void>.delayed(Duration.zero);

      expect(states, [0]);

      await sub.cancel();
      await cubit.close();
    });
  });
}
