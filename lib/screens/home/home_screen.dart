import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../models/couple_model.dart';
import '../../services/auth_service.dart';
import '../../services/couple_service.dart';
import '../../services/streak_service.dart';
import '../../services/location_service.dart';
import '../../services/widget_service.dart';
import '../../services/update_service.dart';
import '../../widgets/days_card.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/distance_card.dart';
import '../../widgets/memory_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    ref.read(widgetServiceProvider).registerWidgetClickCallback((uri) {
      if (WidgetService.isMissYouCallback(uri)) {
        _sendMissYou();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  Future<void> _sendMissYou() async {
    final couple = ref.read(coupleStreamProvider).value;
    if (couple == null) return;
    try {
      await ref.read(coupleServiceProvider).sendMissYou(couple.coupleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('💕 Miss you sent!'),
          backgroundColor: LoveSnapsColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } catch (_) {}
  }

  Future<void> _checkIn(CoupleModel couple) async {
    try {
      await ref.read(streakServiceProvider).checkIn(couple.coupleId);
      _syncWidgets(couple);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔥 Checked in for today!'),
          backgroundColor: LoveSnapsColors.tertiary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _syncWidgets(CoupleModel couple) {
    final myUid = ref.read(authStateProvider).value?.uid ?? '';
    final locationService = ref.read(locationServiceProvider);
    final distanceKm = locationService.calculateDistance(couple, myUid);
    final distanceStr = couple.useManualDistance
        ? (couple.manualStatus == 'together' ? 'Together 💑' : 'Apart 💌')
        : locationService.formatDistance(distanceKm);

    final myCheckedIn = couple.hasCheckedIn(myUid);
    final partnerUid = couple.partnerUid(myUid);
    final partnerCheckedIn = couple.hasCheckedIn(partnerUid);
    final atRisk = ref.read(streakServiceProvider).isStreakAtRisk(
      myCheckedIn: myCheckedIn,
      partnerCheckedIn: partnerCheckedIn,
      lastUpdatedDate: couple.streakLastUpdatedDate,
    );

    final partnerName = 'Partner';

    ref.read(widgetServiceProvider).updateWidgets(
      streakCount: couple.streakCount,
      daysCount: couple.daysTogetherCount,
      partnerName: partnerName,
      distance: distanceStr,
      manualStatus: couple.manualStatus,
      streakAtRisk: atRisk,
      missYouReceived: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(coupleStreamProvider);
    final myUid = ref.watch(authStateProvider).value?.uid ?? '';

    return Scaffold(
      extendBody: true, // For bottom nav
      body: Container(
        decoration: BoxDecoration(
          color: LoveSnapsColors.background,
        ),
        child: Stack(
          children: [
            // Blob Background (simulating radial gradient background)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                duration: 6.seconds,
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.2,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: LoveSnapsColors.tertiaryFixedDim.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                duration: 8.seconds,
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
              ),
            ),

            coupleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (couple) {
                if (couple == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('💔', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text('Not paired yet',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/pair'),
                          child: const Text('Pair with your partner'),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _syncWidgets(couple));

                final atRisk = ref.read(streakServiceProvider).isStreakAtRisk(
                  myCheckedIn: couple.hasCheckedIn(myUid),
                  partnerCheckedIn: couple.hasCheckedIn(couple.partnerUid(myUid)),
                  lastUpdatedDate: couple.streakLastUpdatedDate,
                );
                final myCheckedIn = couple.hasCheckedIn(myUid);

                return CustomScrollView(
                  slivers: [
                    // Custom App Bar
                    SliverAppBar(
                      floating: true,
                      pinned: false,
                      expandedHeight: 70,
                      backgroundColor: Colors.transparent,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite, color: LoveSnapsColors.primary),
                            onPressed: () {},
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            duration: 2.seconds,
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.1, 1.1),
                          ),
                          Text(
                            'LoveSnaps',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: LoveSnapsColors.primary,
                              letterSpacing: -1,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, color: LoveSnapsColors.primary),
                            onPressed: () => context.go('/home/settings'),
                          ),
                        ],
                      ),
                      centerTitle: true,
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), // padded for bottom nav
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (couple.isMilestoneDay)
                            _MilestoneBanner(days: couple.daysTogetherCount)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: -0.5, end: 0),
                          if (couple.isMilestoneDay) const SizedBox(height: 16),

                          // Day Counter Card
                          DaysCard(couple: couple)
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 50.ms)
                              .slideY(begin: 0.15, end: 0),

                          const SizedBox(height: 24),

                          // Grid for Streak and Memory
                          Row(
                            children: [
                              Expanded(
                                child: StreakCard(
                                  couple: couple,
                                  myUid: myUid,
                                  atRisk: atRisk,
                                  myCheckedIn: myCheckedIn,
                                  onCheckIn: () => _checkIn(couple),
                                ).animate()
                                 .fadeIn(duration: 400.ms, delay: 100.ms)
                                 .slideY(begin: 0.15, end: 0),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: MemoryCard().animate()
                                 .fadeIn(duration: 400.ms, delay: 150.ms)
                                 .slideY(begin: 0.15, end: 0),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Distance Card
                          DistanceCard(
                            couple: couple,
                            myUid: myUid,
                            onMissYou: _sendMissYou,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .slideY(begin: 0.15, end: 0),

                          const SizedBox(height: 24),
                          
                          if (couple.nextMilestone != null)
                            _NextMilestoneHint(
                              current: couple.daysTogetherCount,
                              next: couple.nextMilestone!,
                            ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: LoveSnapsColors.surfaceContainerLowest.withOpacity(0.9),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: LoveSnapsShadows.marshmallowShadowMedium,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', isSelected: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
              _NavItem(icon: Icons.music_note_rounded, label: 'Jam', isSelected: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
              _NavItem(icon: Icons.auto_awesome_rounded, label: 'Memories', isSelected: _currentTab == 2, onTap: () => setState(() => _currentTab = 2)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', isSelected: _currentTab == 3, onTap: () => setState(() => _currentTab = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? LoveSnapsColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? LoveSnapsColors.onPrimaryContainer : LoveSnapsColors.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? LoveSnapsColors.onPrimaryContainer : LoveSnapsColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneBanner extends StatelessWidget {
  final int days;
  const _MilestoneBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: LoveSnapsColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowGlow,
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Milestone! Day $days',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LoveSnapsColors.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Celebrate every moment together 💕',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LoveSnapsColors.onTertiaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextMilestoneHint extends StatelessWidget {
  final int current;
  final int next;
  const _NextMilestoneHint({required this.current, required this.next});

  @override
  Widget build(BuildContext context) {
    final remaining = next - current;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: LoveSnapsColors.secondaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LoveSnapsColors.secondaryContainer),
        ),
        child: Text(
          '⭐ $remaining day${remaining == 1 ? '' : 's'} until Day $next',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LoveSnapsColors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
