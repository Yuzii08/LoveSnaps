import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme.dart';
import '../models/couple_model.dart';
import '../services/location_service.dart';

class DistanceCard extends ConsumerWidget {
  final CoupleModel couple;
  final String myUid;
  final VoidCallback onMissYou;

  const DistanceCard({
    super.key,
    required this.couple,
    required this.myUid,
    required this.onMissYou,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationService = ref.read(locationServiceProvider);
    final distanceKm = locationService.calculateDistance(couple, myUid);
    final distanceStr = locationService.formatDistance(distanceKm);

    final isManual = couple.useManualDistance;
    final isTogether = couple.manualStatus == 'together';
    final hideMileage = isManual || distanceKm < 0;

    final recentMissYou = couple.lastMissYouSentAt != null &&
        couple.lastMissYouSentBy != myUid &&
        DateTime.now().difference(couple.lastMissYouSentAt!).inMinutes < 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            LoveSnapsColors.primaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background abstract map icon hint
          Positioned(
            right: -10,
            bottom: 0,
            child: Icon(
              Icons.location_city_rounded,
              size: 100,
              color: LoveSnapsColors.primary.withOpacity(0.04),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: LoveSnapsColors.pinkAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: LoveSnapsColors.pinkAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DISTANCE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LoveSnapsColors.onSurfaceVariant,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!hideMileage) ...[
                Text(
                  distanceStr,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: LoveSnapsColors.primary,
                    height: 1.1,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isTogether ? Icons.favorite_rounded : Icons.flight_takeoff_rounded,
                      color: LoveSnapsColors.tertiary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTogether ? 'together right now' : 'miles apart',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LoveSnapsColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      isTogether ? Icons.favorite_rounded : Icons.explore_off_rounded,
                      color: LoveSnapsColors.pinkAccent,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isTogether ? 'Together 💑' : 'Apart 💌',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: LoveSnapsColors.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: recentMissYou ? [] : LoveSnapsShadows.marshmallowShadowBtn,
                ),
                child: ElevatedButton(
                  onPressed: onMissYou,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: recentMissYou ? LoveSnapsColors.primaryContainer : LoveSnapsColors.pinkAccent,
                    foregroundColor: recentMissYou ? LoveSnapsColors.primary : Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(recentMissYou ? Icons.mark_email_read_rounded : Icons.favorite_rounded, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        recentMissYou ? 'Partner missed you!' : 'Miss You',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ).animate(target: recentMissYou ? 1 : 0).shimmer(duration: 1500.ms, color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }
}
