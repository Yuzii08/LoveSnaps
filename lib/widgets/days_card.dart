import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme.dart';
import '../models/couple_model.dart';

class DaysCard extends StatelessWidget {
  final CoupleModel couple;

  const DaysCard({super.key, required this.couple});

  @override
  Widget build(BuildContext context) {
    final days = couple.daysTogetherCount;
    final startDate = couple.relationshipStartDate;
    
    // Calculate a dummy progress for the heart outline based on days (mod 100 for example, or up to next milestone)
    final progress = couple.nextMilestone != null 
        ? ((days % 100) / 100).clamp(0.0, 1.0) 
        : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LoveSnapsColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: LoveSnapsShadows.marshmallowShadowLarge,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Decorative blur in top right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: LoveSnapsColors.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -40,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox(width: 128, height: 128),
            ),
          ),

          Column(
            children: [
              Text(
                startDate != null ? 'Day $days together 🌙' : 'Not started yet 🌙',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: LoveSnapsColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Every moment counts.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LoveSnapsColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Heart Progress & Image
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Heart Progress
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: 1500.ms,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return CustomPaint(
                          size: const Size(160, 160),
                          painter: HeartProgressPainter(value),
                        );
                      },
                    ),
                    
                    // Center Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: LoveSnapsColors.surfaceContainerLowest, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/marshmallow.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                      begin: -4,
                      end: 4,
                      duration: 3.seconds,
                      curve: Curves.easeInOut,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeartProgressPainter extends CustomPainter {
  final double progress;

  HeartProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 100;
    final scaleY = size.height / 100;
    
    // Rotate canvas by -90 degrees around center to match the HTML design
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-3.14159 / 2);
    canvas.translate(-size.width / 2, -size.height / 2);

    final path = Path()
      ..moveTo(50 * scaleX, 80 * scaleY)
      ..cubicTo(50 * scaleX, 80 * scaleY, 10 * scaleX, 50 * scaleY, 10 * scaleX, 30 * scaleY)
      ..cubicTo(10 * scaleX, 15 * scaleY, 30 * scaleX, 10 * scaleY, 50 * scaleX, 30 * scaleY)
      ..cubicTo(70 * scaleX, 10 * scaleY, 90 * scaleX, 15 * scaleY, 90 * scaleX, 30 * scaleY)
      ..cubicTo(90 * scaleX, 50 * scaleY, 50 * scaleX, 80 * scaleY, 50 * scaleX, 80 * scaleY)
      ..close();

    final bgPaint = Paint()
      ..color = LoveSnapsColors.primaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fgPaint = Paint()
      ..color = LoveSnapsColors.tertiaryFixedDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, bgPaint);

    if (progress > 0) {
      final metrics = path.computeMetrics().first;
      final extractPath = metrics.extractPath(0, metrics.length * progress);
      canvas.drawPath(extractPath, fgPaint);
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(HeartProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
