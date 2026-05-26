// lib/features/notifications/data/datasources/notifications_firebase_data_source.dart
//
// NotificationsFirebaseDataSource — Firestore implementation.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'notifications_remote_data_source.dart';

/// Firestore-backed implementation of [NotificationsRemoteDataSource].
class NotificationsFirebaseDataSource implements NotificationsRemoteDataSource {
  /// Creates a [NotificationsFirebaseDataSource].
  NotificationsFirebaseDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(
      {required String userId}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  @override
  Stream<int> watchUnreadCount({required String userId}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Future<void> markAsRead({required String notificationId}) {
    return _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
