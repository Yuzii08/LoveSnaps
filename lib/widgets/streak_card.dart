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
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onCheckIn,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFff9a9e).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$streak day',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LoveSnapsColors.primary,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'streak',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LoveSnapsColors.onSurfaceVariant,
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
