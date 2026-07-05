import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/message_model.dart';
import 'auth_service.dart';
import 'couple_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService(ref));

final messagesStreamProvider = StreamProvider.autoDispose<List<MessageModel>>((ref) {
  final couple = ref.watch(coupleStreamProvider).value;
  if (couple == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection(AppConstants.couplesCollection)
      .doc(couple.coupleId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
});

class ChatService {
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ChatService(this._ref);

  Future<void> sendMessage(String coupleId, String text) async {
    final uid = _ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null || text.trim().isEmpty) return;

    final message = MessageModel(
      id: '',
      text: text.trim(),
      senderId: uid,
      timestamp: DateTime.now(),
    );

    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('messages')
        .add(message.toFirestore());
  }
}
