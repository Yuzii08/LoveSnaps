import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/couple_model.dart';
import 'local_mock_db.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final coupleServiceProvider = Provider<CoupleService>((ref) => CoupleService());

final coupleStreamProvider = StreamProvider<CoupleModel?>((ref) {
  final service = ref.watch(coupleServiceProvider);
  return service.streamCouple();
});

// ── Service ────────────────────────────────────────────────────────────────

class CoupleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ── Invite Code Generation ─────────────────────────────────────────────

  /// Generates a 6-character alphanumeric invite code and creates a
  /// couples document in Firestore. Returns the new invite code.
  Future<String> generateInviteCode() async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.generateInviteCode();
    }
    final code = _generateRandomCode(AppConstants.inviteCodeLength);
    final now = DateTime.now();

    final couple = CoupleModel(
      coupleId: code,
      memberIds: [_uid],
      inviteCode: code,
      streakCount: 0,
      createdAt: now,
    );

    // Create the couples document
    await _db
        .collection(AppConstants.couplesCollection)
        .doc(code)
        .set(couple.toFirestore());

    // Update current user's coupleId
    await _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .update({'coupleId': code});

    return code;
  }

  /// Joins an existing couple using an invite code (Firestore transaction).
  Future<void> joinWithCode(String code) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.joinWithCode(code);
    }
    final coupleRef = _db.collection(AppConstants.couplesCollection).doc(code.toUpperCase());
    final userRef = _db.collection(AppConstants.usersCollection).doc(_uid);

    await _db.runTransaction((transaction) async {
      final coupleSnap = await transaction.get(coupleRef);
      if (!coupleSnap.exists) {
        throw Exception('Invalid invite code. Please check and try again.');
      }
      final couple = CoupleModel.fromFirestore(coupleSnap);
      if (couple.memberIds.length >= 2) {
        throw Exception('This invite code has already been used.');
      }
      if (couple.memberIds.contains(_uid)) {
        throw Exception("You can't pair with yourself!");
      }

      // Add second partner
      transaction.update(coupleRef, {
        'memberIds': FieldValue.arrayUnion([_uid]),
      });

      // Update this user's coupleId
      transaction.update(userRef, {'coupleId': code.toUpperCase()});
    });
  }

  // ── Relationship Start Date ────────────────────────────────────────────

  Future<void> setStartDate(String coupleId, DateTime date) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.setStartDate(coupleId, date);
    }
    await _db.collection(AppConstants.couplesCollection).doc(coupleId).update({
      'relationshipStartDate': Timestamp.fromDate(date),
    });
  }

  Future<void> confirmStartDate(String coupleId) async {
    // No-op for MVP — first setter's date stands.
    // Could add a "confirmed" flag here for UX polish.
  }

  // ── Real-time Stream ───────────────────────────────────────────────────

  Stream<CoupleModel?> streamCouple() {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.coupleController.stream;
    }
    // First, get the current user's coupleId from their user doc
    return _db
        .collection(AppConstants.usersCollection)
        .doc(_uid)
        .snapshots()
        .asyncExpand((userSnap) {
      final coupleId = userSnap.data()?['coupleId'] as String?;
      if (coupleId == null || coupleId.isEmpty) {
        return Stream.value(null);
      }
      return _db
          .collection(AppConstants.couplesCollection)
          .doc(coupleId)
          .snapshots()
          .map((snap) =>
              snap.exists ? CoupleModel.fromFirestore(snap) : null);
    });
  }

  // ── Manual Status ──────────────────────────────────────────────────────

  Future<void> setManualStatus(String coupleId, String status) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.setManualStatus(coupleId, status);
    }
    await _db.collection(AppConstants.couplesCollection).doc(coupleId).update({
      'manualStatus': status, // 'together' | 'apart'
    });
  }

  Future<void> setUseManualDistance(String coupleId, bool useManual) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.setUseManualDistance(coupleId, useManual);
    }
    await _db.collection(AppConstants.couplesCollection).doc(coupleId).update({
      'useManualDistance': useManual,
    });
  }

  // ── Miss You ───────────────────────────────────────────────────────────

  /// Records a "miss you" tap — Cloud Function will trigger FCM to partner.
  Future<void> sendMissYou(String coupleId) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.sendMissYou(coupleId);
    }
    await _db.collection(AppConstants.couplesCollection).doc(coupleId).update({
      'lastMissYouSentAt': FieldValue.serverTimestamp(),
      'lastMissYouSentBy': _uid,
    });
  }

  Future<void> shareJam(String coupleId, String title, String artist) async {
    await _db.collection(AppConstants.couplesCollection).doc(coupleId).update({
      'currentJamTitle': title,
      'currentJamArtist': artist,
      'currentJamSharedBy': _uid,
      'currentJamSharedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I ambiguity
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
