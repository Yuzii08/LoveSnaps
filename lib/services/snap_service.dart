import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String get _uid => _auth.currentUser!.uid;

  /// Takes a photo using the device camera (or drops down to file picker on Web)
  Future<XFile?> capturePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1350,
        imageQuality: 85,
      );
      return file;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Uploads a photo to Firebase Storage and saves its metadata in Firestore.
  Future<void> uploadSnap({
    required String coupleId,
    required XFile file,
    required String caption,
  }) async {
    final snapId = const Uuid().v4();
    final filename = '$snapId.jpg';
    final ref = _storage.ref().child('couples/$coupleId/snaps/$filename');

    String imageUrl;
    
    // Web handles uploads via bytes
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      imageUrl = await uploadTask.ref.getDownloadURL();
    } else {
      final uploadTask = await ref.putFile(
        File(file.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      imageUrl = await uploadTask.ref.getDownloadURL();
    }

    final snap = SnapModel(
      id: snapId,
      imageUrl: imageUrl,
      senderId: _uid,
      caption: caption,
      timestamp: DateTime.now(),
    );

    // Save metadata under couples/{coupleId}/snaps
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
