// lib/features/auth/data/datasources/auth_firebase_data_source.dart
//
// AuthFirebaseDataSource — Firebase implementation of AuthRemoteDataSource.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_remote_data_source.dart';

/// Firebase-backed implementation of [AuthRemoteDataSource].
///
/// Wraps [FirebaseAuth], [GoogleSignIn.instance], and [FirebaseFirestore] to
/// provide authentication and user profile persistence.
class AuthFirebaseDataSource implements AuthRemoteDataSource {
  /// Creates an [AuthFirebaseDataSource].
  AuthFirebaseDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _writeUserProfile(credential.user!, provider: 'email');
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    final userCredential = await _firebaseAuth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _writeUserProfile(userCredential.user!, provider: 'google');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }

  Future<void> _writeUserProfile(
    User user, {
    required String provider,
  }) async {
    await _firestore.collection('users').doc(user.uid).set(
      {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'provider': provider,
      },
      SetOptions(merge: true),
    );
  }
}
