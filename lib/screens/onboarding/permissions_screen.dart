import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme.dart';
import '../../services/notification_service.dart';
import '../../services/location_service.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _notifGranted = false;
  bool _locationGranted = false;
  bool _loading = false;

  Future<void> _requestNotifications() async {
    setState(() => _loading = true);
    final granted = await ref.read(notificationServiceProvider).hasPermission();
    if (!granted) {
      await ref.read(notificationServiceProvider).initialize();
      final nowGranted =
          await ref.read(notificationServiceProvider).hasPermission();
      setState(() => _notifGranted = nowGranted);
    } else {
      setState(() => _notifGranted = true);
    }
    setState(() => _loading = false);
  }

  Future<void> _requestLocation() async {
    setState(() => _loading = true);
    final granted =
        await ref.read(locationServiceProvider).requestLocationPermission();
    setState(() {
      _locationGranted = granted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'A few permissions',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These make the widget and nudges work. You can change them any time in Settings.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LoveSnapsColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),

              // Permission cards
              _PermissionCard(
                emoji: '🔔',
                title: 'Notifications',
                subtitle:
                    'Get streak reminders, "miss you" nudges, and milestone alerts.',
                granted: _notifGranted,
                onTap: _loading ? null : _requestNotifications,
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              _PermissionCard(
                emoji: '📍',
                title: 'Location (optional)',
                subtitle:
                    'Show how far apart you are on the widget. Never stored long-term.',
                granted: _locationGranted,
                onTap: _loading ? null : _requestLocation,
                optional: true,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0),

              const Spacer(),

              // Widget instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      LoveSnapsColors.tertiaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: LoveSnapsColors.tertiaryContainer, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📱', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Text(
                          'Add the widget',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '• Android: Long-press your home screen → Widgets → find LoveSnaps\n'
                      '• iOS: Long-press home screen → tap + → search LoveSnaps',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LoveSnapsColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text("Let's go! 💕"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback? onTap;
  final bool optional;

  const _PermissionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: granted
            ? LoveSnapsColors.tertiary.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: granted
              ? LoveSnapsColors.tertiary
              : LoveSnapsColors.primaryContainer,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (optional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: LoveSnapsColors.tertiaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'optional',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: LoveSnapsColors.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: LoveSnapsColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (granted)
            const Icon(Icons.check_circle_rounded,
                color: LoveSnapsColors.tertiary, size: 28)
          else
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: LoveSnapsColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Allow',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
