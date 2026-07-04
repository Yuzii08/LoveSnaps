import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import 'local_mock_db.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final streakServiceProvider =
    Provider<StreakService>((ref) => StreakService());

// ── Service ────────────────────────────────────────────────────────────────

class StreakService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;
  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ── Check-in ───────────────────────────────────────────────────────────

  /// Marks this user as checked-in for today.
  /// If both partners have checked in on the same day, increments the streak.
  /// This is the MVP "qualifying interaction" — one heart-tap per day.
  Future<void> checkIn(String coupleId) async {
    if (AppConstants.useLocalMock) {
      return LocalMockDb.checkIn(coupleId);
    }
    final coupleRef =
        _db.collection(AppConstants.couplesCollection).doc(coupleId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(coupleRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
      if (memberIds.isEmpty) return;

      final lastDate = data['streakLastUpdatedDate'] as String?;
      final isPartnerA = _uid == memberIds[0];
      final myKey = isPartnerA ? 'partnerACheckedIn' : 'partnerBCheckedIn';
      final partnerKey = isPartnerA ? 'partnerBCheckedIn' : 'partnerACheckedIn';
      final partnerCheckedIn = data[partnerKey] as bool? ?? false;
      final alreadyCheckedIn = data[myKey] as bool? ?? false;

      if (alreadyCheckedIn) return; // Already checked in today, no-op

      final updates = <String, dynamic>{myKey: true};

      if (partnerCheckedIn) {
        // Both checked in — determine streak delta
        if (lastDate == _today) {
          // Already updated today (shouldn't happen, but guard it)
        } else if (lastDate == _yesterday()) {
          // Consecutive day — extend streak
          updates['streakCount'] = FieldValue.increment(1);
        } else {
          // Gap — restart streak at 1
          updates['streakCount'] = 1;
        }
        updates['streakLastUpdatedDate'] = _today;
        // Reset both check-in flags for tomorrow
        updates[myKey] = true; // keep this user marked
        // Note: the Cloud Function resets both flags at midnight
      }

      transaction.update(coupleRef, updates);
    });
  }

  // ── At-Risk Detection ──────────────────────────────────────────────────

  /// Returns true if it's past [AppConstants.streakAtRiskHour] local time
  /// and neither partner has checked in yet today.
  bool isStreakAtRisk({
    required bool myCheckedIn,
    required bool partnerCheckedIn,
    required String? lastUpdatedDate,
  }) {
    final now = DateTime.now();
    if (now.hour < AppConstants.streakAtRiskHour) return false;
    if (myCheckedIn && partnerCheckedIn) return false;
    if (lastUpdatedDate == _today) return false; // already done today
    return true;
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  String _yesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return DateFormat('yyyy-MM-dd').format(yesterday);
  }
}
