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
          backgroundColor: LoveSnapsColors.pinkAccent,
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
      extendBody: true,
      backgroundColor: LoveSnapsColors.background,
      body: coupleAsync.when(
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
                  Text('Not paired yet', style: Theme.of(context).textTheme.headlineSmall),
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

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Custom App Bar (Matches HTML header)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: LoveSnapsColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.mood_rounded, color: LoveSnapsColors.primary),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'LoveSnaps',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: LoveSnapsColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: LoveSnapsColors.primary),
                          onPressed: () {},
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                          duration: 2.seconds,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.1, 1.1),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
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

                      const SizedBox(height: 16),

                      // Grid for Streak and Jam
                      Row(
                        children: [
                          Expanded(
                            child: StreakCard(
                              couple: couple,
                              onCheckIn: () => _checkIn(couple),
                            ).animate()
                             .fadeIn(duration: 400.ms, delay: 100.ms)
                             .slideY(begin: 0.15, end: 0),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: LoveSnapsColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: LoveSnapsShadows.marshmallowShadowCard,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.music_note_rounded, color: LoveSnapsColors.secondary),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Currently\nListening',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: LoveSnapsColors.onSecondaryContainer,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.15, end: 0),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Distance Card
                      DistanceCard(
                        couple: couple,
                        myUid: myUid,
                        onMissYou: _sendMissYou,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms)
                          .slideY(begin: 0.15, end: 0),

                      const SizedBox(height: 32),
                      
                      // Recent Snaps
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Snaps', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: LoveSnapsColors.primary)),
                          Text('VIEW ALL', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LoveSnapsColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          children: [
                            _buildSnapPlaceholder('Morning ☕️', 'assets/images/placeholder_snap_1.jpg'),
                            const SizedBox(width: 16),
                            _buildSnapPlaceholder('Park run 🐶', 'assets/images/placeholder_snap_2.jpg'),
                            const SizedBox(width: 16),
                            Container(
                              width: 140,
                              height: 180,
                              decoration: BoxDecoration(
                                color: LoveSnapsColors.primaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: LoveSnapsColors.primaryContainer, width: 2, style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: LoveSnapsColors.primaryContainer),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Add Snap', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LoveSnapsColors.primaryContainer)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSnapPlaceholder(String label, String assetPath) {
    return Container(
      width: 140,
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: LoveSnapsColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            // We would put the NetworkImage or AssetImage here.
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LoveSnapsColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(9999),
        boxShadow: LoveSnapsShadows.marshmallowShadowBtn,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, isSelected: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
              _NavItem(icon: Icons.music_note_rounded, isSelected: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
              _NavItem(icon: Icons.auto_awesome_motion_rounded, isSelected: _currentTab == 2, onTap: () => setState(() => _currentTab = 2)),
              _NavItem(icon: Icons.person_rounded, isSelected: _currentTab == 3, onTap: () => setState(() => _currentTab = 3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? LoveSnapsColors.secondaryContainer : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? LoveSnapsColors.onSecondaryContainer : LoveSnapsColors.onSurfaceVariant,
          size: 24,
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
        boxShadow: LoveSnapsShadows.marshmallowShadowCard,
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
