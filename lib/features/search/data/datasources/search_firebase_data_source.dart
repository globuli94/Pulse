// lib/features/search/data/datasources/search_firebase_data_source.dart
//
// SearchFirebaseDataSource — Firestore implementation of user-search queries.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../profile/domain/entities/user_profile.dart';

/// Firestore-backed data source for user-search operations.
class SearchFirebaseDataSource {
  /// Creates a [SearchFirebaseDataSource].
  SearchFirebaseDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Returns up to 20 [UserProfile]s whose displayName prefix-matches [query].
  ///
  /// Returns an empty list immediately when [query] is empty, avoiding an
  /// unnecessary Firestore read.
  Future<List<UserProfile>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('displayName')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UserProfile(
        uid: doc.id,
        displayName: (data['displayName'] as String?) ?? '',
        bio: (data['bio'] as String?) ?? '',
        avatarUrl: data['avatarUrl'] as String?,
        postCount: (data['postCount'] as int?) ?? 0,
        followerCount: (data['followerCount'] as int?) ?? 0,
        followingCount: (data['followingCount'] as int?) ?? 0,
      );
    }).toList();
  }
}
