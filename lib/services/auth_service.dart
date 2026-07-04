import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/user_model.dart';
import 'local_mock_db.dart';

// ── Mock User for local testing ─────────────────────────────────────────────
class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  MockUser({required this.uid, this.email, this.displayName});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Providers ──────────────────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  if (AppConstants.useLocalMock) {
    return LocalMockDb.userController.stream.map((user) {
      if (user == null) return null;
      return MockUser(uid: user.uid, email: user.email, displayName: user.displayName);
    });
  }
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserDocProvider = StreamProvider<UserModel?>((ref) {
  if (AppConstants.useLocalMock) {
    return LocalMockDb.userController.stream;
  }
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .snapshots()
          .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ── Service ────────────────────────────────────────────────────────────────

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser {
    if (AppConstants.useLocalMock) {
      final uid = LocalMockDb.getCurrentUid();
      if (uid == null) return null;
      return MockUser(uid: uid);
    }
    return _auth.currentUser;
  }

  // ── Email / Password ───────────────────────────────────────────────────

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.signUp(email, password, displayName);
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(displayName);
      final user = UserModel(
        uid: credential.user!.uid,
        displayName: displayName,
        email: email,
        createdAt: DateTime.now(),
      );
      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toFirestore());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.signIn(email, password);
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists) {
        // Re-create user doc if missing (edge case)
        final user = UserModel(
          uid: credential.user!.uid,
          displayName: credential.user!.displayName ?? '',
          email: email,
          createdAt: DateTime.now(),
        );
        await _db
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(user.toFirestore());
        return user;
      }
      return UserModel.fromFirestore(doc);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<void> signOut() async {
    if (AppConstants.useLocalMock) {
      await LocalMockDb.signOut();
      return;
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    if (AppConstants.useLocalMock) {
      return;
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── FCM Token ──────────────────────────────────────────────────────────

  Future<void> updateFcmToken(String token) async {
    if (AppConstants.useLocalMock) {
      return;
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'fcmToken': token,
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
