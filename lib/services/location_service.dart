import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants.dart';
import '../models/couple_model.dart';
import 'local_mock_db.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// ── Service ────────────────────────────────────────────────────────────────

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ── Permission ─────────────────────────────────────────────────────────

  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  // ── Location Update ────────────────────────────────────────────────────

  /// Fetches current position and writes to Firestore.
  /// Called on app foreground + background WorkManager task every 20 min.
  Future<void> updateMyLocation(String coupleId) async {
    final hasPermission = await hasLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      if (AppConstants.useLocalMock) {
        await LocalMockDb.updateLocation(coupleId, position.latitude, position.longitude);
        return;
      }

      await _db
          .collection(AppConstants.couplesCollection)
          .doc(coupleId)
          .update({
        'latestLocations.$_uid': {
          'lat': position.latitude,
          'lng': position.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      // Silently fail — location is optional
      rethrow;
    }
  }

  // ── Distance Calculation ───────────────────────────────────────────────

  /// Computes Haversine distance in kilometers between two partners.
  double calculateDistance(CoupleModel couple, String myUid) {
    final partnerUid = couple.partnerUid(myUid);
    final myLoc = couple.latestLocations[myUid];
    final partnerLoc = couple.latestLocations[partnerUid];

    if (myLoc == null || partnerLoc == null) return -1;

    return _haversineDistance(
      myLoc.lat, myLoc.lng,
      partnerLoc.lat, partnerLoc.lng,
    );
  }

  /// Returns a formatted distance string (auto km/m).
  String formatDistance(double distanceKm) {
    if (distanceKm < 0) return '—';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  // ── Haversine Formula ──────────────────────────────────────────────────

  double _haversineDistance(
    double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRad(double deg) => deg * pi / 180;
}
