import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme.dart';
import '../models/couple_model.dart';

class StreakCard extends StatelessWidget {
  final CoupleModel couple;
  final String myUid;
  final bool atRisk;
  final bool myCheckedIn;
  final VoidCallback onCheckIn;

  const StreakCard({
    super.key,
    required this.couple,
    required this.myUid,
    required this.atRisk,
    required this.myCheckedIn,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final streak = couple.streakCount;

    return GestureDetector(
      onTap: myCheckedIn ? null : onCheckIn,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: LoveSnapsColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(32),
          boxShadow: LoveSnapsShadows.marshmallowShadowMedium,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flame icon container
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      size: 36,
                      color: LoveSnapsColors.tertiary,
                    ),
                  ),
                ).animate(
                  onPlay: (c) => c.repeat(reverse: true),
                ).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 2.seconds,
                ),
                
                Text(
                  '$streak Days',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: LoveSnapsColors.onTertiaryContainer,
                  ),
                ),
                Text(
                  myCheckedIn ? 'Current Streak!' : 'Tap to Check In',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: LoveSnapsColors.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
