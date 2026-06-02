// test/features/profile/presentation/bloc/profile_posts_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/posts/domain/entities/post.dart';
import 'package:pulse/features/posts/domain/repositories/posts_repository.dart';
import 'package:pulse/features/profile/presentation/bloc/profile_posts_bloc.dart';

class MockPostsRepository extends Mock implements PostsRepository {}

void main() {
  late MockPostsRepository mockPostsRepository;

  final testPost = Post(
    id: 'post-1',
    userId: 'uid1',
    text: 'Hello world',
    createdAt: DateTime(2024),
  );

  setUp(() {
    mockPostsRepository = MockPostsRepository();
  });

  group('ProfilePostsBloc', () {
    blocTest<ProfilePostsBloc, ProfilePostsState>(
      'emits [ProfilePostsLoading, ProfilePostsLoaded] when getPostsByUser succeeds',
      build: () {
        when(() => mockPostsRepository.getPostsByUser('uid1'))
            .thenAnswer((_) async => [testPost]);
        return ProfilePostsBloc(postsRepository: mockPostsRepository);
      },
      act: (bloc) =>
          bloc.add(const ProfilePostsLoadRequested(uid: 'uid1')),
      expect: () => [
        const ProfilePostsLoading(),
        ProfilePostsLoaded(posts: [testPost]),
      ],
      verify: (_) {
        verify(() => mockPostsRepository.getPostsByUser('uid1')).called(1);
      },
    );

    blocTest<ProfilePostsBloc, ProfilePostsState>(
      'emits [ProfilePostsLoading, ProfilePostsError] when getPostsByUser throws',
      build: () {
        when(() => mockPostsRepository.getPostsByUser('uid1'))
            .thenThrow(Exception('network error'));
        return ProfilePostsBloc(postsRepository: mockPostsRepository);
      },
      act: (bloc) =>
          bloc.add(const ProfilePostsLoadRequested(uid: 'uid1')),
      expect: () => [
        const ProfilePostsLoading(),
        isA<ProfilePostsError>(),
      ],
    );

    blocTest<ProfilePostsBloc, ProfilePostsState>(
      'emits [ProfilePostsLoading, ProfilePostsLoaded] with empty list',
      build: () {
        when(() => mockPostsRepository.getPostsByUser('uid2'))
            .thenAnswer((_) async => []);
        return ProfilePostsBloc(postsRepository: mockPostsRepository);
      },
      act: (bloc) =>
          bloc.add(const ProfilePostsLoadRequested(uid: 'uid2')),
      expect: () => [
        const ProfilePostsLoading(),
        const ProfilePostsLoaded(posts: []),
      ],
    );

    blocTest<ProfilePostsBloc, ProfilePostsState>(
      'BUG-001c: emits updates when posts stream emits new posts (real-time)',
      build: () {
        final post1 = Post(
          id: 'post-1',
          userId: 'uid1',
          text: 'First post',
          createdAt: DateTime(2024),
        );

        // Mock getPostsByUser to return initial posts
        when(() => mockPostsRepository.getPostsByUser('uid1'))
            .thenAnswer((_) async => [post1]);

        return ProfilePostsBloc(postsRepository: mockPostsRepository);
      },
      act: (bloc) {
        bloc.add(const ProfilePostsLoadRequested(uid: 'uid1'));
      },
      expect: () => [
        const ProfilePostsLoading(),
        isA<ProfilePostsLoaded>(),
      ],
      verify: (_) {
        // Verify that the repository method was called to fetch posts
        verify(() => mockPostsRepository.getPostsByUser('uid1')).called(1);
      },
    );
  });
}
