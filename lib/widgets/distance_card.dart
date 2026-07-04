import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        ? (isTogether ? 'Together 💑' : 'Apart 💌')
        : distanceStr;

    final recentMissYou = couple.lastMissYouSentAt != null &&
        couple.lastMissYouSentBy != myUid &&
        DateTime.now().difference(couple.lastMissYouSentAt!).inMinutes < 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LoveSnapsColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: LoveSnapsShadows.marshmallowShadowMedium,
        border: recentMissYou 
            ? Border.all(color: LoveSnapsColors.tertiary, width: 2) 
            : null,
      ),
      child: Column(
        children: [
          // Graphic section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: LoveSnapsColors.primary,
                ),
              ),
              
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dashed line representation using simple Container mapping
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Flex(
                          direction: Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: List.generate(
                            (constraints.constrainWidth() / 8).floor(),
                            (_) => SizedBox(
                              width: 4,
                              height: 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: LoveSnapsColors.primaryContainer,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Distance badge
                    Container(
                      color: LoveSnapsColors.surfaceContainerLowest,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        displayText,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LoveSnapsColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: LoveSnapsColors.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Button
          if (recentMissYou)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: LoveSnapsColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💌', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Your partner misses you!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: LoveSnapsColors.onTertiaryContainer,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1500.ms, color: Colors.white54)
          else
            GestureDetector(
              onTap: onMissYou,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: LoveSnapsColors.tertiaryFixedDim,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: LoveSnapsShadows.marshmallowGlow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, color: LoveSnapsColors.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Send a nudge',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: LoveSnapsColors.tertiary, // text-on-tertiary-fixed approximation
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
