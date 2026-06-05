// lib/features/comments/data/repositories/comments_repository_impl.dart
//
// CommentsRepositoryImpl — data-layer implementation of CommentsRepository.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/comment.dart';
import '../../domain/repositories/comments_repository.dart';
import '../datasources/comments_remote_data_source.dart';

/// Concrete implementation of [CommentsRepository] backed by Firestore.
class CommentsRepositoryImpl implements CommentsRepository {
  /// Creates a [CommentsRepositoryImpl].
  CommentsRepositoryImpl({required CommentsRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final CommentsRemoteDataSource _dataSource;

  @override
  Stream<List<Comment>> watchComments({required String postId}) {
    return _dataSource
        .watchComments(postId: postId)
        .map((maps) => maps.map(_fromMap).toList());
  }

  @override
  Stream<int> watchCommentCount(String postId) {
    return _dataSource.watchCommentCount(postId);
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String text,
  }) {
    return _dataSource.addComment(
      postId: postId,
      authorId: authorId,
      text: text,
    );
  }

  Comment _fromMap(Map<String, dynamic> map) {
    final ts = map['createdAt'];
    final DateTime createdAt;
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else {
      createdAt = DateTime.now();
    }

    return Comment(
      id: map['id'] as String? ?? '',
      postId: map['postId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}
