import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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

  String get _uid => _ref.read(authServiceProvider).currentUser!.uid;

  /// Sends a text message
  Future<void> sendMessage(String coupleId, String text) async {
    if (text.trim().isEmpty) return;

    final message = MessageModel(
      id: '',
      text: text.trim(),
      senderId: _uid,
      timestamp: DateTime.now(),
      read: false,
    );

    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('messages')
        .add(message.toFirestore());
  }

  /// Sends an animated sticker message (represented as a sticker ID like 'hug', 'heart')
  Future<void> sendStickerMessage(String coupleId, String stickerName) async {
    final message = MessageModel(
      id: '',
      text: 'Sent a sticker 🧸',
      senderId: _uid,
      timestamp: DateTime.now(),
      sticker: stickerName,
      read: false,
    );

    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('messages')
        .add(message.toFirestore());
  }

  /// Uploads a photo to Supabase or Base64 fallback, then sends a photo message.
  Future<void> sendPhotoMessage(String coupleId, XFile file) async {
    final messageId = const Uuid().v4();
    final bytes = await file.readAsBytes();
    String imageUrl = '';

    if (AppConstants.supabaseUrl != 'YOUR_SUPABASE_URL') {
      try {
        final filename = '$messageId.jpg';
        final path = 'couples/$coupleId/chat/$filename';
        await Supabase.instance.client.storage
            .from(AppConstants.supabaseSnapsBucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
            );
        imageUrl = Supabase.instance.client.storage
            .from(AppConstants.supabaseSnapsBucket)
            .getPublicUrl(path);
      } catch (e) {
        debugPrint('Supabase chat upload failed, falling back to Base64: $e');
      }
    }

    if (imageUrl.isEmpty) {
      final base64Str = base64Encode(bytes);
      imageUrl = 'data:image/jpeg;base64,$base64Str';
    }

    final message = MessageModel(
      id: '',
      text: 'Sent a photo 📷',
      senderId: _uid,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      read: false,
    );

    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('messages')
        .add(message.toFirestore());
  }

  /// Marks all incoming unread messages as read.
  Future<void> markMessagesAsRead(String coupleId) async {
    final snap = await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('messages')
        .where('senderId', isNotEqualTo: _uid)
        .where('read', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  /// Sets the typing state in Firestore.
  Future<void> setTyping(String coupleId, bool typing) async {
    await _ref.read(coupleServiceProvider).setTypingState(coupleId, typing);
  }
}
