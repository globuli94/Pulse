// Copyright 2024 Social Media Company. All rights reserved.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulse/features/search/domain/repositories/search_repository.dart';
import 'package:pulse/features/search/presentation/bloc/search_bloc.dart';
import 'package:pulse/features/profile/domain/entities/user_profile.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late MockSearchRepository mockSearchRepository;

  setUp(() {
    mockSearchRepository = MockSearchRepository();
  });

  group('SearchBloc', () {
    test('initial state is SearchInitial', () {
      final searchBloc = SearchBloc(repository: mockSearchRepository);
      expect(searchBloc.state, isA<SearchInitial>());
    });

    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged(query: \'\') emits SearchInitial (no Firestore call)',
      build: () => SearchBloc(repository: mockSearchRepository),
      act: (bloc) => bloc.add(const SearchQueryChanged(query: '')),
      expect: () => [
        isA<SearchInitial>(),
      ],
      verify: (bloc) {
        verifyNever(() => mockSearchRepository.searchUsers(any()));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged(query: \'al\') after debounce emits [SearchLoading, SearchLoaded(users: [...])]',
      build: () {
        final testUser = UserProfile(
          uid: 'test-uid',
          displayName: 'Albert',
          bio: 'Test bio',
          avatarUrl: null,
          postCount: 0,
          followerCount: 5,
          followingCount: 3,
        );
        when(() => mockSearchRepository.searchUsers('al'))
            .thenAnswer((_) async => [testUser]);
        return SearchBloc(repository: mockSearchRepository);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(query: 'al')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>(),
      ],
      wait: const Duration(milliseconds: 600),
    );

    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged(query: \'al\') when repository throws emits [SearchLoading, SearchFailure]',
      build: () {
        when(() => mockSearchRepository.searchUsers('al'))
            .thenThrow(Exception('Search failed'));
        return SearchBloc(repository: mockSearchRepository);
      },
      act: (bloc) => bloc.add(const SearchQueryChanged(query: 'al')),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchFailure>(),
      ],
      wait: const Duration(milliseconds: 600),
    );

    blocTest<SearchBloc, SearchState>(
      'rapid successive SearchQueryChanged events only trigger one repository call (debounce)',
      build: () {
        final testUser = UserProfile(
          uid: 'test-uid',
          displayName: 'Alice',
          bio: 'Test bio',
          avatarUrl: null,
          postCount: 0,
          followerCount: 5,
          followingCount: 3,
        );
        when(() => mockSearchRepository.searchUsers(any()))
            .thenAnswer((_) async => [testUser]);
        return SearchBloc(repository: mockSearchRepository);
      },
      act: (bloc) {
        bloc.add(const SearchQueryChanged(query: 'a'));
        bloc.add(const SearchQueryChanged(query: 'al'));
        bloc.add(const SearchQueryChanged(query: 'ali'));
        bloc.add(const SearchQueryChanged(query: 'alic'));
        bloc.add(const SearchQueryChanged(query: 'alice'));
      },
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchLoaded>(),
      ],
      wait: const Duration(milliseconds: 600),
      verify: (bloc) {
        verify(() => mockSearchRepository.searchUsers('alice'))
            .called(1);
      },
    );
  });
}
