import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/couple_model.dart';

class DaysCard extends StatelessWidget {
  final CoupleModel couple;

  const DaysCard({super.key, required this.couple});

  @override
  Widget build(BuildContext context) {
    final days = couple.daysTogetherCount;
    // Calculate progress for heart fill (e.g. 75%)
    final progress = couple.nextMilestone != null 
        ? ((days % 100) / 100).clamp(0.0, 1.0) 
        : 0.75; // Default to 0.75 for visual if no milestone

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: LoveSnapsColors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          // Decorative Blobs
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFc2e8ff).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: const SizedBox(),
            ),
          ),

          // Content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Day $days',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: LoveSnapsColors.primary,
                  height: 1.1,
                ),
              ),
              Text(
                'together 🌙',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: LoveSnapsColors.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              
              // Filled Heart Mask
              SizedBox(
                width: 64,
                height: 64,
                child: ClipPath(
                  clipper: _HeartClipper(),
                  child: Container(
                    color: LoveSnapsColors.surfaceVariant,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOut,
                        width: double.infinity,
                        height: 64 * progress,
                        color: LoveSnapsColors.pinkAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toInt()}% to Anniversary',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: LoveSnapsColors.primary.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double width = size.width;
    double height = size.height;

    Path path = Path();
    path.moveTo(width / 2, height / 5);
    // Left curve
    path.cubicTo(
      5 * width / 14, 0,
      0, 0,
      0, 2 * height / 5,
    );
    path.cubicTo(
      0, 3 * height / 5,
      width / 7, 5 * height / 7,
      width / 2, height,
    );
    // Right curve
    path.cubicTo(
      6 * width / 7, 5 * height / 7,
      width, 3 * height / 5,
      width, 2 * height / 5,
    );
    path.cubicTo(
      width, 0,
      9 * width / 14, 0,
      width / 2, height / 5,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
