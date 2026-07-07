import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/mood_model.dart';
import 'couple_service.dart';

final moodServiceProvider = Provider<MoodService>((ref) => MoodService(ref));

final moodsHistoryStreamProvider = StreamProvider.autoDispose<List<MoodModel>>((ref) {
  final couple = ref.watch(coupleStreamProvider).value;
  if (couple == null) return Stream.value([]);

  // Stream last 100 mood logs for history calendar
  return FirebaseFirestore.instance
      .collection(AppConstants.couplesCollection)
      .doc(couple.coupleId)
      .collection('moods')
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => MoodModel.fromFirestore(doc)).toList());
});

class MoodService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  MoodService(this._ref);

  /// Triggers mood check-in on the couple service.
  Future<void> updateMood(String coupleId, String emoji) async {
    await _ref.read(coupleServiceProvider).setMood(coupleId, emoji);
  }
}
