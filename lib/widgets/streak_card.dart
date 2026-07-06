import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/couple_model.dart';

class StreakCard extends StatelessWidget {
  final CoupleModel couple;
  final VoidCallback onCheckIn;

  const StreakCard({
    super.key, 
    required this.couple,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final streak = couple.streakCount;

    return Container(
      decoration: BoxDecoration(
        color: LoveSnapsColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onCheckIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFA07A), Color(0xFFFF6B6B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$streak day',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LoveSnapsColors.primary,
                    height: 1.1,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'streak 🔥',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: LoveSnapsColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
