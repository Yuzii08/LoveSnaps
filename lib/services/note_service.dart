import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/note_model.dart';
import 'auth_service.dart';
import 'couple_service.dart';
import 'streak_service.dart';

final noteServiceProvider = Provider<NoteService>((ref) => NoteService(ref));

final notesStreamProvider = StreamProvider.autoDispose<List<NoteModel>>((ref) {
  final couple = ref.watch(coupleStreamProvider).value;
  if (couple == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(AppConstants.couplesCollection)
      .doc(couple.coupleId)
      .collection('notes')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList());
});

class NoteService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  NoteService(this._ref);

  String get _uid => _ref.read(authServiceProvider).currentUser!.uid;

  /// Sends a note to the notes collection and automatically triggers streak check-in.
  Future<void> sendNote(String coupleId, String prompt, String text) async {
    if (text.trim().isEmpty) return;

    final note = NoteModel(
      id: '',
      prompt: prompt,
      text: text.trim(),
      senderId: _uid,
      timestamp: DateTime.now(),
    );

    // Save note
    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('notes')
        .add(note.toFirestore());

    // Fulfill daily streak check-in as a qualifying interaction
    try {
      await _ref.read(streakServiceProvider).checkIn(coupleId);
    } catch (e) {
      // If already checked in or mock mode, ignore error
    }
  }
}
