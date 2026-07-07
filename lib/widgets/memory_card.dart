import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme.dart';

class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8), // p-base
      decoration: BoxDecoration(
        color: LoveSnapsColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        children: [
          // The image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1, // keeping it square-ish like the streak card
              child: Image.asset(
                'assets/images/polaroid.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Blur caption
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.white.withValues(alpha: 0.8),
                  child: Text(
                    'Last weekend ✨',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: LoveSnapsColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
