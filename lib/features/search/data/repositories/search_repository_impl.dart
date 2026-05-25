// lib/features/search/data/repositories/search_repository_impl.dart
//
// SearchRepositoryImpl — concrete implementation of SearchRepository.

import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_firebase_data_source.dart';

/// Firebase-backed implementation of [SearchRepository].
class SearchRepositoryImpl implements SearchRepository {
  /// Creates a [SearchRepositoryImpl].
  SearchRepositoryImpl({required SearchFirebaseDataSource dataSource})
      : _dataSource = dataSource;

  final SearchFirebaseDataSource _dataSource;

  @override
  Future<List<UserProfile>> searchUsers(String query) =>
      _dataSource.searchUsers(query);
}
