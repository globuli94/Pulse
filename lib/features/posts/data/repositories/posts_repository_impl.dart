// lib/features/posts/data/repositories/posts_repository_impl.dart
//
// PostsRepositoryImpl — concrete implementation of PostsRepository.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/post.dart';
import '../../domain/entities/posts_feed_page.dart';
import '../../domain/repositories/posts_repository.dart';
import '../datasources/posts_remote_data_source.dart';

/// Firebase-backed implementation of [PostsRepository].
class PostsRepositoryImpl implements PostsRepository {
  /// Creates a [PostsRepositoryImpl].
  PostsRepositoryImpl({required PostsRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final PostsRemoteDataSource _dataSource;

  @override
  Stream<List<Post>> watchFeed() {
    return _dataSource.watchFeed().map(
          (maps) => maps.map(_mapToPost).toList(),
        );
  }

  @override
  Future<PostsFeedPage> fetchFeed({
    Object? cursor,
    int limit = 15,
    List<String>? authorIds,
  }) async {
    final raw = await _dataSource.fetchFeed(
      cursor: cursor as DocumentSnapshot?,
      limit: limit,
      authorIds: authorIds,
    );
    return PostsFeedPage(
      posts: raw.posts.map(_mapToPost).toList(),
      hasMore: raw.hasMore,
      cursor: raw.cursor,
    );
  }

  @override
  Future<void> createPost({
    required String text,
    required String userId,
    required String displayName,
    String? avatarUrl,
    XFile? image,
  }) {
    return _dataSource.createPost(
      text: text,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      image: image,
    );
  }

  @override
  Future<void> deletePost({required String postId, required String userId}) {
    return _dataSource.deletePost(postId: postId, userId: userId);
  }

  @override
  Future<List<Post>> getPostsByUser(String uid) async {
    final maps = await _dataSource.getPostsByUser(uid);
    return maps.map(_mapToPost).toList();
  }

  @override
  Stream<List<Post>> watchPostsByUser(String uid) {
    return _dataSource
        .watchPostsByUser(uid)
        .map((maps) => maps.map(_mapToPost).toList());
  }

  @override
  Future<void> likePost({required String postId, required String userId}) =>
      _dataSource.likePost(postId: postId, userId: userId);

  @override
  Future<void> unlikePost({required String postId, required String userId}) =>
      _dataSource.unlikePost(postId: postId, userId: userId);

  @override
  Future<bool> isLiked({required String postId, required String userId}) =>
      _dataSource.isLiked(postId: postId, userId: userId);

  @override
  Stream<bool> watchIsLiked({required String postId, required String userId}) =>
      _dataSource.watchIsLiked(postId: postId, userId: userId);

  @override
  Stream<int> watchLikeCount(String postId) =>
      _dataSource.watchLikeCount(postId);

  Post _mapToPost(Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    final DateTime dateTime;
    if (createdAt is Timestamp) {
      dateTime = createdAt.toDate();
    } else {
      dateTime = DateTime.now();
    }

    return Post(
      id: map['id'] as String,
      userId: map['userId'] as String,
      displayName: map['displayName'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      text: map['text'] as String,
      imageUrl: map['imageUrl'] as String?,
      createdAt: dateTime,
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
