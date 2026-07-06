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
    // Calculate progress to next anniversary (out of 365 days)
    final progress = (days % 365) / 365.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF0F3), // Soft bubblegum
            Color(0xFFF2EFFF), // Soft lavender
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          // Decorative Blobs
          Positioned(
            top: -50,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFc2e8ff).withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'together ☁️💕',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: LoveSnapsColors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Filled Heart Mask
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LoveSnapsColors.pinkAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                width: 80,
                height: 80,
                child: ClipPath(
                  clipper: _HeartClipper(),
                  child: Container(
                    color: Colors.white.withOpacity(0.7),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutBack,
                        width: double.infinity,
                        height: 80 * progress,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              LoveSnapsColors.pinkAccent,
                              LoveSnapsColors.pinkAccentDark,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${(progress * 100).toInt()}% to Anniversary',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LoveSnapsColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
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
