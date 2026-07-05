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
    final displayText = isManual
        ? (isTogether ? '0 miles' : 'unknown miles')
        : distanceStr;

    final recentMissYou = couple.lastMissYouSentAt != null &&
        couple.lastMissYouSentBy != myUid &&
        DateTime.now().difference(couple.lastMissYouSentAt!).inMinutes < 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LoveSnapsColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background abstract map icon hint
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.map_rounded,
              size: 120,
              color: LoveSnapsColors.primary.withOpacity(0.05),
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: LoveSnapsColors.pinkAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'DISTANCE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LoveSnapsColors.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                displayText,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: LoveSnapsColors.primary,
                  height: 1.1,
                  fontSize: 32,
                ),
              ),
              Text(
                isTogether ? 'together' : 'apart',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: LoveSnapsColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              
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
                      Text(recentMissYou ? 'Partner missed you!' : 'Miss You'),
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
