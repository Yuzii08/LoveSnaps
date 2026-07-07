import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/event_model.dart';
import 'auth_service.dart';
import 'couple_service.dart';

final eventServiceProvider = Provider<EventService>((ref) => EventService(ref));

final eventsStreamProvider = StreamProvider.autoDispose<List<EventModel>>((ref) {
  final couple = ref.watch(coupleStreamProvider).value;
  if (couple == null) return Stream.value([]);

  // Stream events sorted by target date ascending (next event first)
  return FirebaseFirestore.instance
      .collection(AppConstants.couplesCollection)
      .doc(couple.coupleId)
      .collection('events')
      .orderBy('date', descending: false)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
});

class EventService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  EventService(this._ref);

  String get _uid => _ref.read(authServiceProvider).currentUser!.uid;

  /// Creates a countdown event for the couple.
  Future<void> addEvent(String coupleId, String title, DateTime date) async {
    if (title.trim().isEmpty) return;

    final event = EventModel(
      id: '',
      title: title.trim(),
      date: date,
      senderId: _uid,
      timestamp: DateTime.now(),
    );

    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('events')
        .add(event.toFirestore());
  }

  /// Deletes a countdown event.
  Future<void> deleteEvent(String coupleId, String eventId) async {
    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('events')
        .doc(eventId)
        .delete();
  }
}
