import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/posts/domain/repositories/posts_repository.dart';
import 'package:pulse/features/posts/presentation/bloc/create_post_bloc.dart';

class MockPostsRepository extends Mock implements PostsRepository {}

class MockXFile extends Mock implements XFile {
  MockXFile({required String path}) : _path = path;
  final String _path;

  @override
  String get path => _path;

  @override
  String get name => _path.split('/').last;
}

void main() {
  group('CreatePostBloc', () {
    late MockPostsRepository mockPostsRepository;
    late CreatePostBloc createPostBloc;

    setUp(() {
      mockPostsRepository = MockPostsRepository();
      createPostBloc = CreatePostBloc(repository: mockPostsRepository);
    });

    tearDown(() {
      createPostBloc.close();
    });

    group('CreatePostImageSelected', () {
      test('emits CreatePostImageAttached when image is selected', () async {
        final mockImage = MockXFile(path: '/path/to/image.jpg');
        createPostBloc.add(CreatePostImageSelected(image: mockImage));

        await Future.delayed(const Duration(milliseconds: 100));

        expect(createPostBloc.state, isA<CreatePostImageAttached>());
        expect((createPostBloc.state as CreatePostImageAttached).image.path,
            equals('/path/to/image.jpg'));
      });
    });

    group('CreatePostImageRemoved', () {
      test('emits CreatePostInitial when image is removed', () async {
        final mockImage = MockXFile(path: '/path/to/image.jpg');
        createPostBloc.add(CreatePostImageSelected(image: mockImage));
        await Future.delayed(const Duration(milliseconds: 100));

        createPostBloc.add(const CreatePostImageRemoved());
        await Future.delayed(const Duration(milliseconds: 100));

        expect(createPostBloc.state, isA<CreatePostInitial>());
      });
    });

    group('CreatePostSubmitted', () {
      test('emits [CreatePostSubmitting, CreatePostSuccess] on success',
          () async {
        when(() => mockPostsRepository.createPost(
              text: any(named: 'text'),
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              avatarUrl: any(named: 'avatarUrl'),
              image: any(named: 'image'),
            )).thenAnswer((_) async {});

        createPostBloc.add(const CreatePostSubmitted(
          text: 'Test post',
          userId: 'user-123',
          displayName: 'Test User',
          avatarUrl: null,
        ));

        await Future.delayed(const Duration(milliseconds: 200));

        expect(createPostBloc.state, isA<CreatePostSuccess>());
      });

      test('emits [CreatePostSubmitting, CreatePostFailure] on error', () async {
        when(() => mockPostsRepository.createPost(
              text: any(named: 'text'),
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              avatarUrl: any(named: 'avatarUrl'),
              image: any(named: 'image'),
            )).thenThrow(Exception('Upload failed'));

        createPostBloc.add(const CreatePostSubmitted(
          text: 'Test post',
          userId: 'user-123',
          displayName: 'Test User',
          avatarUrl: null,
        ));

        await Future.delayed(const Duration(milliseconds: 200));

        expect(createPostBloc.state, isA<CreatePostFailure>());
      });

      test('calls repository.createPost with correct parameters', () async {
        when(() => mockPostsRepository.createPost(
              text: any(named: 'text'),
              userId: any(named: 'userId'),
              displayName: any(named: 'displayName'),
              avatarUrl: any(named: 'avatarUrl'),
              image: any(named: 'image'),
            )).thenAnswer((_) async {});

        createPostBloc.add(CreatePostSubmitted(
          text: 'My test post',
          userId: 'user-123',
          displayName: 'Test User',
          avatarUrl: 'https://example.com/avatar.jpg',
        ));

        await Future.delayed(const Duration(milliseconds: 200));

        verify(() => mockPostsRepository.createPost(
          text: 'My test post',
          userId: 'user-123',
          displayName: 'Test User',
          avatarUrl: 'https://example.com/avatar.jpg',
          image: any(named: 'image'),
        )).called(1);
      });
    });
  });
}
