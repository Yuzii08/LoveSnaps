import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/location_service.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> {
  bool _isLoading = true;
  bool _hasPermission = false;
  double? _myLat;
  double? _myLng;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoading = true);
    final locationService = ref.read(locationServiceProvider);
    
    // Explicitly request permissions if not granted
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    
    _hasPermission = status.isGranted;
    
    if (_hasPermission) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _myLat = position.latitude;
        _myLng = position.longitude;

        final couple = ref.read(coupleStreamProvider).value;
        if (couple != null) {
          // Force an update to Firestore so widgets get it too
          await locationService.updateMyLocation(couple.coupleId);
        }
      } catch (e) {
        // Handle error
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    // Converts from degrees to radians
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final lon1Rad = lon1 * pi / 180;
    final lon2Rad = lon2 * pi / 180;

    final y = sin(lon2Rad - lon1Rad) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) -
        sin(lat1Rad) * cos(lat2Rad) * cos(lon2Rad - lon1Rad);

    final bearingRad = atan2(y, x);
    return (bearingRad * 180 / pi + 360) % 360; // in degrees
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleStreamProvider);
    final myUid = ref.read(currentUserDocProvider).value?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Partner Radar', style: TextStyle(color: Colors.white)),
      ),
      body: coupleAsync.when(
        data: (couple) {
          if (couple == null) return const SizedBox.shrink();
          
          final partnerUid = couple.partnerUid(myUid);
          final partnerLoc = couple.latestLocations[partnerUid];
          
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator(color: LoveSnapsColors.primary));
          }
          
          if (!_hasPermission) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_rounded, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text(
                    'Location Permission Denied',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initLocation,
                    child: const Text('Grant Permission'),
                  )
                ],
              ),
            );
          }
          
          if (partnerLoc == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore_off_rounded, size: 64, color: Colors.white54),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for partner\'s location...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'They need to open the app with location enabled.',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ).animate().fadeIn(),
            );
          }
          
          if (_myLat == null || _myLng == null) {
             return const Center(child: Text('Could not get your location', style: TextStyle(color: Colors.white)));
          }

          final bearing = _calculateBearing(_myLat!, _myLng!, partnerLoc.lat, partnerLoc.lng);
          final distanceKm = ref.read(locationServiceProvider).calculateDistance(couple, myUid);
          final distanceStr = ref.read(locationServiceProvider).formatDistance(distanceKm);

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Radar Background
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LoveSnapsColors.primary.withValues(alpha: 0.3), width: 2),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 2.seconds)
                     .fadeOut(duration: 2.seconds),
                     
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LoveSnapsColors.primary.withValues(alpha: 0.5), width: 4),
                        color: LoveSnapsColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    
                    // Arrow pointing to partner
                    Transform.rotate(
                      angle: bearing * pi / 180,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigation_rounded, color: LoveSnapsColors.primary, size: 64),
                          const SizedBox(height: 120), // pushes arrow to the edge
                        ],
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .moveY(begin: -5, end: 5, duration: 1.seconds),
                     
                    // Center dot (You)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                
                const SizedBox(height: 64),
                Text(
                  'Partner is',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  distanceStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: LoveSnapsColors.primary)),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
