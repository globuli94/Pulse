// lib/features/search/domain/repositories/search_repository.dart
//
// SearchRepository — abstract contract for user-search operations.

import '../../../profile/domain/entities/user_profile.dart';

/// Repository contract for searching users by display name.
abstract class SearchRepository {
  /// Returns up to 20 [UserProfile]s whose displayName starts with [query].
  ///
  /// Returns an empty list when [query] is empty.
  Future<List<UserProfile>> searchUsers(String query);
}
