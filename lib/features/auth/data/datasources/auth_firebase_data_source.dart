// lib/features/auth/data/datasources/auth_firebase_data_source.dart
//
// AuthFirebaseDataSource — Firebase implementation of AuthRemoteDataSource.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/exceptions/auth_exception.dart';
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
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _writeUserProfile(credential.user!, provider: 'email');
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(e, 'Account creation failed. Please try again.');
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(e, 'Sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _writeUserProfile(userCredential.user!, provider: 'google');
      }
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(e, 'Sign-in failed. Please try again.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _toAuthException(
        e,
        'Failed to send reset email. Please try again.',
      );
    }
  }

  /// Maps a [FirebaseAuthException] to a domain [AuthException] with a
  /// user-friendly message. Falls back to [fallback] for unknown codes.
  AuthException _toAuthException(FirebaseAuthException e, String fallback) {
    const codeMessages = <String, String>{
      'user-not-found': 'No account found for this email.',
      'wrong-password': 'Incorrect password.',
      'invalid-email': 'Please enter a valid email address.',
      'user-disabled': 'This account has been disabled.',
      'network-request-failed': 'Network error. Please check your connection.',
      'invalid-credential': 'Incorrect email or password.',
      'email-already-in-use': 'An account already exists for this email.',
      'weak-password': 'Password must be at least 6 characters.',
    };
    return AuthException(
      code: e.code,
      message: codeMessages[e.code] ?? fallback,
    );
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
        'displayName': user.displayName ?? '',
        'username': user.displayName ?? user.email?.split('@').first ?? '',
        'bio': '',
        'avatarUrl': null,
        'followerCount': 0,
        'followingCount': 0,
        'postCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
