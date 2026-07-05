import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../models/snap_model.dart';
import 'auth_service.dart';

final snapServiceProvider = Provider<SnapService>((ref) => SnapService());

final snapsStreamProvider = StreamProvider<List<SnapModel>>((ref) {
  final userDocAsync = ref.watch(currentUserDocProvider);
  return userDocAsync.when(
    data: (userDoc) {
      if (userDoc == null || userDoc.coupleId == null || userDoc.coupleId!.isEmpty) {
        return Stream.value([]);
      }
      return ref.watch(snapServiceProvider).streamSnaps(userDoc.coupleId!);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

class SnapService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String get _uid => _auth.currentUser!.uid;

  /// Takes a photo using the device camera (or drops down to file picker on Web)
  Future<XFile?> capturePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 25, // Heavily compressed so base64 data fits comfortably under 1MB document limit
      );
      return file;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Converts image to Base64 and saves directly in Firestore, bypassing Storage upgrade
  Future<void> uploadSnap({
    required String coupleId,
    required XFile file,
    required String caption,
  }) async {
    final snapId = const Uuid().v4();
    final bytes = await file.readAsBytes();
    final base64Str = base64Encode(bytes);
    final imageUrl = 'data:image/jpeg;base64,$base64Str';

    final snap = SnapModel(
      id: snapId,
      imageUrl: imageUrl,
      senderId: _uid,
      caption: caption,
      timestamp: DateTime.now(),
    );

    // Save metadata and base64 string directly under couples/{coupleId}/snaps
    await _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('snaps')
        .doc(snapId)
        .set(snap.toFirestore());
  }

  /// Streams list of snaps sorted by timestamp descending
  Stream<List<SnapModel>> streamSnaps(String coupleId) {
    return _db
        .collection(AppConstants.couplesCollection)
        .doc(coupleId)
        .collection('snaps')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((query) => query.docs
            .map((doc) => SnapModel.fromFirestore(doc))
            .toList());
  }
}
